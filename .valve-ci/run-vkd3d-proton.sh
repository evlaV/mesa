#!/usr/bin/env bash
# shellcheck disable=SC2035 # FIXME glob

set -ex

INSTALL=$(realpath -s "$PWD"/install)

# Set up the driver environment.
# Modifiying here directly LD_LIBRARY_PATH may cause problems when
# using a command wrapper. Hence, we will just set it when running the
# command.
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$INSTALL/lib/:/vkd3d-proton-tests/lib"

# Set up the driver environment.
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.${VK_CPU:-$(uname -m)}.json

RESULTS="$PWD/${VKD3D_PROTON_RESULTS_DIR:-results}"
mkdir -p "$RESULTS"

# Set environment for Wine.
export WINEDEBUG="-all"
export WINEPREFIX="/vkd3d-proton-wine64"
export WINEESYNC=1

# wrapper to supress +x to avoid spamming the log
quiet() {
    set +x
    "$@"
    set -x
}

quiet printf "%s\n" "Running vkd3d-proton testsuite..."

set +e
if ! /vkd3d-proton-tests/bin/d3d12 > "$RESULTS/vkd3d-proton.log";
then
    # Check if the executable finished (ie. no segfault).
    if ! grep "tests executed" "$RESULTS/vkd3d-proton.log" > /dev/null; then
        error printf "%s\n" "Failed, see vkd3d-proton.log!"
        exit 1
    fi

    # Collect all the failures
    VKD3D_PROTON_RESULTS="${VKD3D_PROTON_RESULTS:-vkd3d-proton-results}"
    RESULTSFILE="$RESULTS/$VKD3D_PROTON_RESULTS.txt"
    mkdir -p .gitlab-ci/vkd3d-proton
    grep "Test failed" "$RESULTS"/vkd3d-proton.log > "$RESULTSFILE"

    # Gather the list expected failures
    if [ -f "$INSTALL/$VKD3D_PROTON_RESULTS.txt" ]; then
        cp "$INSTALL/$VKD3D_PROTON_RESULTS.txt" \
           ".gitlab-ci/vkd3d-proton/$VKD3D_PROTON_RESULTS.txt.baseline"
    else
        touch ".gitlab-ci/vkd3d-proton/$VKD3D_PROTON_RESULTS.txt.baseline"
    fi

    # Make sure that the failures found in this run match the current expectation
    if ! diff -q ".gitlab-ci/vkd3d-proton/$VKD3D_PROTON_RESULTS.txt.baseline" "$RESULTSFILE"; then
        error printf "%s\n" "Changes found, see vkd3d-proton.log!"
        quiet diff --color=always -u ".gitlab-ci/vkd3d-proton/$VKD3D_PROTON_RESULTS.txt.baseline" "$RESULTSFILE"
        exit 1
    fi
fi

printf "%s\n" "vkd3d-proton execution: SUCCESS"

exit 0
