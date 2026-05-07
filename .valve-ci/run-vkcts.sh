#!/usr/bin/env bash
# shellcheck disable=SC2086 # we want word splitting

set -eux

VK_DRIVER=${VK_DRIVER:-radeon}
DRIVER_NAME=${DRIVER_NAME:-radv}
DEQP_VER=${DEQP_VER:-vk}

# Set up the driver environment.
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/"$VK_DRIVER"_icd.${VK_CPU:-$(uname -m)}.json

# linking the expected mesa ci install folder to our install location (/mesa)
ln -s /mesa "$PWD/install"

RESULTS="$PWD/${DEQP_RESULTS_DIR:-results}"
mkdir -p "$RESULTS"

if [ "$DEQP_VER" = "vk" ] && [ -z "$VK_DRIVER" ]; then
    echo 'VK_DRIVER must be to something like "radeon" or "intel" for the test run'
    exit 1
fi

EXPECTATIONS_FOLDER=/mesa

FILE_ARGS=""

touch $EXPECTATIONS_FOLDER/fails.txt

# There must be a single baseline expected fails list, this lets us cat together
# xfails from multiple possible sources. Do we actually use this, though?
cat_if_exists() {
  prefix=$1
  kind=$2
  if [ -e "$EXPECTATIONS_FOLDER/$prefix-$kind.txt" ]; then
    cat "$EXPECTATIONS_FOLDER/$prefix-$kind.txt" >> "$EXPECTATIONS_FOLDER/$kind.txt"
  fi
}

add_if_exists() {
  if [ -e "$EXPECTATIONS_FOLDER/$2" ]; then
    FILE_ARGS="$FILE_ARGS $1 $EXPECTATIONS_FOLDER/$2"
  fi
}

# remove duplicate values to avoid reading the same file multiple times
for prefix in $({
  echo "all"
  echo "$DRIVER_NAME"
  echo "$GPU_VERSION"
} | sort -u); do
  cat_if_exists "$prefix" fails
  add_if_exists "--flakes" "$prefix-flakes.txt"
  add_if_exists "--skips" "$prefix-skips.txt"
  add_if_exists "--single-thread" "$prefix-single-thread.txt"
done

if [[ $CI_JOB_NAME != *full* ]]; then
  touch $EXPECTATIONS_FOLDER/all-slow-skips.txt
  FILE_ARGS="$FILE_ARGS --skips $EXPECTATIONS_FOLDER/all-slow-skips.txt"
  add_if_exists "--skips" "$GPU_VERSION-slow-skips.txt"
fi

report_load() {
    echo "System load: $(cut -d' ' -f1-3 < /proc/loadavg)"
    echo "# of CPU cores: $(grep -c processor /proc/cpuinfo)"
}

set +e
deqp-runner \
    suite \
    --suite $EXPECTATIONS_FOLDER/deqp-$DEQP_SUITE.toml \
    --output $RESULTS \
    --baseline $EXPECTATIONS_FOLDER/fails.txt \
    $FILE_ARGS \
    --testlog-to-xml /deqp-vk-main/executor/testlog-to-xml \
    --fraction-start ${CI_NODE_INDEX:-1} \
    --fraction $((CI_NODE_TOTAL * ${DEQP_FRACTION:-1})) \
    --jobs ${CI_JOB_CONCURRENCY:-4} \
    ${DEQP_RUNNER_MAX_FAILS:+--max-fails "$DEQP_RUNNER_MAX_FAILS"} \

DEQP_EXITCODE=$?

set +x
report_load
set -x

# Remove all but the first 50 individual XML files uploaded as artifacts, to
# save fd.o space when you break everything.
find $RESULTS -name \*.xml | \
    sort -n |
    sed -n '1,+49!p' | \
    xargs rm -f

# If any QPA XMLs are there, then include the XSL/CSS in our artifacts.
find $RESULTS -name \*.xml \
    -exec cp /deqp-vk-main/testlog.css /deqp-vk-main/testlog.xsl "$RESULTS/" ";" \
    -quit

# Compress results.csv to save on bandwidth during the upload of artifacts to
# GitLab. This reduces the size in a VKCTS run from 135 to 7.6MB, and takes
# 0.17s on a Ryzen 5950X (16 threads, 0.95s when limited to 1 thread).
zstd --rm -T0 -8q "$RESULTS/results.csv" -o "$RESULTS/results.csv.zst"

exit $DEQP_EXITCODE
