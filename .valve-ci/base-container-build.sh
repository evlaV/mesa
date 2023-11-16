#!/bin/bash

set -eux

echo "Building '$DEQP_BRANCH'"

# VKCTS dependencies
pacman --noconfirm -Suy git ninja cmake python3 libx11 libglvnd

# Build vkcts
git clone https://github.com/KhronosGroup/VK-GL-CTS.git -b $DEQP_BRANCH --depth 1 /VK-GL-CTS
python3 /VK-GL-CTS/external/fetch_sources.py --insecure
cmake -S /VK-GL-CTS -B /deqp -G Ninja \
      -DDEQP_TARGET=surfaceless \
      -DCMAKE_BUILD_TYPE=Release
ninja -C /deqp external/vulkancts/modules/vulkan/deqp-vk

# Cleanup the build folder
rm -rf /deqp/external/{glslang,spirv-tools,amber}
rm -rf /deqp/external/vulkancts/framework
rm -rf /deqp/external/vulkancts/modules/vulkan/vk-default
rm -rf /deqp/framework
find /deqp -iname '*cmake*' -o -name '*ninja*' -o -name '*.o' -o -name '*.a' | xargs rm -rf
strip /deqp/external/vulkancts/modules/vulkan/deqp-vk

# Copy out the mustpass lists we want.
mkdir -p /deqp/mustpass
for mustpass in $(< /VK-GL-CTS/external/vulkancts/mustpass/main/vk-default.txt) ; do
    cat /VK-GL-CTS/external/vulkancts/mustpass/main/$mustpass \
        >> /deqp/mustpass/vk-master.txt
done
rm -rf /VK-GL-CTS

# Install deqp-runner
pacman --noconfirm -S rust
cargo install --root /usr/local deqp-runner
pacman --noconfirm -R rust

# Mesa dependencies
pacman --noconfirm -Suy git openssh python-mako libxml2 libx11 xorgproto libdrm libxshmfence wayland wayland-protocols zstd elfutils llvm libunwind libxrandr valgrind meson glslang

# Clear the caches
pacman --noconfirm -Scc
rm /var/cache/pacman/pkg/*
rm -rf ./root/.cargo/
