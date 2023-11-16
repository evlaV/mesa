#!/usr/bin/env python3

# Copyright © 2022 Valve Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice (including the next
# paragraph) shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

from jinja2 import Environment, FileSystemLoader
from argparse import ArgumentParser
from shlex import quote
from os import environ, path
import json


def yaml_single_quote_escape(string):
    return string.replace("'", "''")


def shlex_quote(string):
    return quote(string)


def shlex_quote_2(string):
    return shlex_quote(shlex_quote(string))


def jinja2_escape(string):
    return string.replace(
        "{{", "{{ '{{' }}").replace(
            "{%", "{{ '{%' }}").replace(
                "{#", "{{ '{#' }}")


def safe_quote(string):
    return jinja2_escape(yaml_single_quote_escape(string))


parser = ArgumentParser()
parser.add_argument('--template', default='b2c.yml.jinja2.jinja2')
parser.add_argument('--job-volume-exclusions', nargs='?', default='')
parser.add_argument('--volume', action='append')
parser.add_argument('--mount-volume', action='append')
parser.add_argument('--local-container', default='alpine:latest')
parser.add_argument('--working-dir')
args = parser.parse_args()

env = Environment(loader=FileSystemLoader(path.dirname(args.template)),
                  trim_blocks=True, lstrip_blocks=True)
env.filters['shlex_quote'] = shlex_quote_2
env.filters['safe_quote'] = safe_quote

template = env.get_template(path.basename(args.template))

values = {}

# Pass all the environment variables prefixed by CI_TRON_
for key in environ:
    if key.startswith("CI_TRON_"):
        values[key.removeprefix("CI_TRON_").lower()] = environ[key]

tags = environ.get("CI_RUNNER_TAGS")
try:
    values['tags'] = json.loads(tags)
except json.decoder.JSONDecodeError:
    values['tags'] = tags.split(",")
values['runner_id'] = environ.get("CI_RUNNER_DESCRIPTION")
values['template'] = args.template

if len(args.job_volume_exclusions) > 0:
    exclusions = args.job_volume_exclusions.split(",")
    values['job_volume_exclusions'] = [excl for excl in exclusions if len(excl) > 0]
values['working_dir'] = args.working_dir

assert(len(args.local_container) > 0)
values['local_container'] = args.local_container.replace(
    # Use the gateway's pull-through registry cache to reduce load on fd.o.
    'registry.freedesktop.org', '{{ fdo_proxy_registry }}'
).replace(
    'registry.gitlab.steamos.cloud', 'ci-gateway:8010'
)

f = open(path.splitext(path.basename(args.template))[0], "w")
f.write(template.render(values))
f.close()
