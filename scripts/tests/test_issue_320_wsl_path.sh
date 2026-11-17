#!/bin/bash
# Regression test for Issue #320: Windows path normalization in WSL
# This test extracts the REAL xilinx_setup_vivado function from the
# production script and tests it with mocked dependencies.
# If the fix is removed from production code, this test WILL FAIL.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$SCRIPT_DIR/steps/00_setup_xilinx.source_bash"

echo "Running Issue #320 Regression Test..."

# --- Setup mock environment ---
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/mnt/d/AMDDesignTools/2026.1/Vivado/bin"
touch "$TEST_DIR/mnt/d/AMDDesignTools/2026.1/Vivado/bin/vivado"
chmod +x "$TEST_DIR/mnt/d/AMDDesignTools/2026.1/Vivado/bin/vivado"

# --- Stub dependencies used by xilinx_setup_vivado ---
warning() { echo "WARNING: $*" >&2; }
error() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "INFO: $*"; }
is_command_available() { command -v "$1" >/dev/null 2>&1; }
xilinx_collect_vivado_candidates() { return 0; }
xilinx_sort_discovery() { return 0; }

# --- Mock wslpath to redirect d:\... to our temp dir ---
wslpath() {
    if [[ "$1" == "-u" ]]; then
        local p="$2"
        # Convert d:\AMDDesignTools\... -> TEST_DIR/mnt/d/AMDDesignTools/...
        local drive="${p:0:1}"
        local rest="${p:2}"
        rest="${rest//\\//}"
        echo "$TEST_DIR/mnt/${drive,,}${rest}"
    fi
}

# --- Extract the REAL xilinx_setup_vivado function from production script ---
# We use awk to grab everything from the function signature to the closing brace
eval "$(awk '/^xilinx_setup_vivado \(\)/,/^}/' "$TARGET")"

# --- Test Case 1: Windows backslash path should be normalized ---
echo ""
echo "TEST 1: Windows backslash path (d:\\AMDDesignTools\\2026.1\\Vivado)"
export XILINX_VIVADO='d:\AMDDesignTools\2026.1\Vivado'
xilinx_setup_vivado

if [[ "$XILINX_VIVADO" == "$TEST_DIR/mnt/d/AMDDesignTools/2026.1/Vivado" ]]; then
    echo "  PASS: XILINX_VIVADO normalized to $XILINX_VIVADO"
else
    echo "  FAIL: XILINX_VIVADO='$XILINX_VIVADO'"
    exit 1
fi

if [[ ":$PATH:" == *":$XILINX_VIVADO/bin:"* ]]; then
    echo "  PASS: PATH updated correctly"
else
    echo "  FAIL: PATH not updated. PATH=$PATH"
    exit 1
fi

# --- Test Case 2: Already-valid Unix path should NOT be mangled ---
echo ""
echo "TEST 2: Unix path with colon (edge case, should not be converted)"
export XILINX_VIVADO="$TEST_DIR/mnt/d/AMDDesignTools/2026.1/Vivado"
# Reset PATH to check it gets added
export PATH="/usr/bin:/bin"
xilinx_setup_vivado

if [[ "$XILINX_VIVADO" == "$TEST_DIR/mnt/d/AMDDesignTools/2026.1/Vivado" ]]; then
    echo "  PASS: Unix path preserved unchanged"
else
    echo "  FAIL: Unix path was mangled to '$XILINX_VIVADO'"
    exit 1
fi

if [[ ":$PATH:" == *":$XILINX_VIVADO/bin:"* ]]; then
    echo "  PASS: PATH updated for Unix path"
else
    echo "  FAIL: PATH not updated for Unix path"
    exit 1
fi

echo ""
echo "ALL TESTS PASSED"
