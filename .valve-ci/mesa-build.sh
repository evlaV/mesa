#!/bin/bash

set -eux

CFLAGS+=' -g1'
CXXFLAGS+=' -g1'

export CFLAGS CXXFLAGS

# Compile libdrm - disabled since we want to use system libraries as much as possible
if [ "${COMPILE_LIBDRM_WITH_MESA:-0}" == '1' ]; then
    git clone https://gitlab.freedesktop.org/mesa/drm.git drm
    pushd drm
    meson build --prefix=/usr -Dintel=disabled -Dradeon=disabled -Dnouveau=disabled -Dvmwgfx=disabled
    ninja -C build install
    popd
    rm -rf drm
fi

# Install the expectations and execution scripts
mkdir -p /mesa
cp src/amd/ci/*.txt .gitlab-ci/all-skips.txt /mesa/
cp .gitlab-ci/setup-test-env.sh /usr/local/bin/
cp .valve-ci/run-vkcts.sh /usr/local/bin/
cp .valve-ci/run-vkd3d-proton.sh /usr/local/bin/

# Jupiter: only build RADV, the rest comes from upstream/Arch Mesa
# In particular:
#  - drop all dri, gallium drivers
#  - drop all but amd vulkan drivers
#  - drop all vulkan layers
#  - disable egl
#  - drop all gallium-foo toggles
#  - disable gbm, disable gles2, glvnd, glx, lmsensors, osmesa
#  - drop shared-glapi
meson setup --prefix=/usr --buildtype=plain . build \
-D b_ndebug=true \
-D b_lto=false \
-D platforms=x11,wayland \
-D gallium-drivers= \
-D gallium-va=disabled \
-D android-libbacktrace=disabled \
-D vulkan-drivers=amd \
-D vulkan-layers= \
-D egl=disabled \
-D gbm=disabled \
-D gles1=disabled \
-D gles2=disabled \
-D glvnd=disabled \
-D glx=disabled \
-D libunwind=enabled \
-D llvm=enabled \
-D lmsensors=disabled \
-D microsoft-clc=disabled \
-D valgrind=enabled \
-D radv-build-id="0fc57c2cf625a235fe81e41877a40609c43e451a"

ninja -C build
meson compile -C build
meson install -C build
