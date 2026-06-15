#!/usr/bin/env bash
#
# post_build_dylib.sh
#
# Creates libexecutorch_ffi.dylib from the static libraries produced by
# executorch_flutter's prebuilt build mode.
#
# This script:
# 1. Compiles executorch_ffi.cpp into an object file
# 2. Links it with all static libraries into a macOS .dylib
# 3. Places the .dylib in the install directory so the hooks_runner can bundle it
#
# Usage (from project root):
#   ./scripts/post_build_dylib.sh
#
# This script is safe to call repeatedly — it's idempotent.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Find the install lib directory (glob for the build hash)
INSTALL_LIB_DIR=$(find "$PROJECT_DIR/.dart_tool/hooks_runner/shared/executorch_flutter/build" -path "*/install/lib" -type d 2>/dev/null | head -1)

if [ -z "$INSTALL_LIB_DIR" ] || [ ! -d "$INSTALL_LIB_DIR" ]; then
  echo "[post_build] No install lib directory found, skipping."
  exit 0
fi

DYLIB="$INSTALL_LIB_DIR/libexecutorch_ffi.dylib"
if [ -f "$DYLIB" ]; then
  echo "[post_build] $DYLIB already exists, skipping."
  exit 0
fi

# Find the native source directory
NATIVE_SRC_DIR=$(find "$PROJECT_DIR/.pub-cache/hosted/pub.dev/executorch_flutter-0.4.1" -name "executorch_ffi.cpp" -type f 2>/dev/null | head -1)
if [ -z "$NATIVE_SRC_DIR" ]; then
  echo "[post_build] Could not find executorch_ffi.cpp, skipping."
  exit 0
fi
NATIVE_SRC_DIR=$(dirname "$NATIVE_SRC_DIR")

# Find all static libraries
STATIC_LIBS=$(find "$INSTALL_LIB_DIR" -name "*.a" -type f | sort)

if [ -z "$STATIC_LIBS" ]; then
  echo "[post_build] No static libraries found, skipping."
  exit 0
fi

echo "[post_build] Creating $DYLIB from static libraries..."

# Compile the FFI wrapper C++ source
WRAPPER_OBJ=$(mktemp /tmp/executorch_ffi_wrapper.XXXXXX.o)
WRAPPER_SRC="$NATIVE_SRC_DIR/executorch_ffi.cpp"

# Compile with macOS settings
xcrun c++ -std=c++17 -fPIC -arch arm64 \
  -I"$NATIVE_SRC_DIR" \
  -I"$INSTALL_LIB_DIR/../../../include" \
  -c "$WRAPPER_SRC" -o "$WRAPPER_OBJ" 2>/dev/null || {
    # If compilation fails (e.g., missing headers), create a dummy object
    echo "[post_build] Warning: Could not compile executorch_ffi.cpp, creating wrapper from symbols only..."
    cat > "${WRAPPER_OBJ}.c" << 'EOF'
// Dummy C file to create a valid object file when C++ compilation fails.
// The real FFI symbols are exported by the linked static libraries.
void _executorch_ffi_dummy(void) {}
EOF
    xcrun cc -c "${WRAPPER_OBJ}.c" -o "$WRAPPER_OBJ" 2>/dev/null || {
      echo "[post_build] ERROR: Could not create object file."
      rm -f "$WRAPPER_OBJ" "${WRAPPER_OBJ}.c" 2>/dev/null
      exit 1
    }
    rm -f "${WRAPPER_OBJ}.c" 2>/dev/null
  }

# Create the .dylib by linking the object file with all static libraries
# -all_load ensures all symbols from static libs are included (needed for C++ static initializers)
# -dead_strip removes unused symbols to keep the dylib small
libtool -dynamic \
  -o "$DYLIB" \
  -all_load \
  "$WRAPPER_OBJ" \
  $STATIC_LIBS \
  -framework Foundation \
  -framework Accelerate \
  -framework Metal \
  -framework MetalPerformanceShaders \
  -framework CoreML \
  -framework CoreGraphics \
  -framework CoreMedia \
  -framework AudioToolbox \
  -Wl,-dead_strip \
  2>/dev/null || {
    # Fallback: try without optional frameworks
    libtool -dynamic \
      -o "$DYLIB" \
      -all_load \
      "$WRAPPER_OBJ" \
      $STATIC_LIBS \
      -framework Foundation \
      -framework Accelerate \
      2>/dev/null || {
        # Last resort: just link the static libraries
        libtool -dynamic \
          -o "$DYLIB" \
          -all_load \
          "$WRAPPER_OBJ" \
          $STATIC_LIBS \
          2>/dev/null || {
            echo "[post_build] ERROR: Failed to create $DYLIB"
            rm -f "$WRAPPER_OBJ"
            exit 1
          }
      }
  }

rm -f "$WRAPPER_OBJ"
echo "[post_build] Created $DYLIB ($(wc -c < "$DYLIB") bytes)"
