#!/bin/bash
set -e

echo "Copying native libraries to jniLibs..."

# Define architectures
ARCHS="arm64-v8a armeabi-v7a x86 x86_64"

# Define build type (release or debug)
BUILD_TYPE="${1:-release}"
echo "Using build type: $BUILD_TYPE"

# Source directory for built libraries
if [ "$BUILD_TYPE" = "release" ]; then
    SRC_DIR="android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni"
else
    SRC_DIR="android/build/intermediates/library_jni/debug/copyDebugJniLibsProjectOnly/jni"
fi

# Destination directory
DEST_DIR="android/src/main/jniLibs"

# Create destination directories
for arch in $ARCHS; do
    mkdir -p "$DEST_DIR/$arch"
done

# Copy libraries for each architecture
for arch in $ARCHS; do
    if [ -d "$SRC_DIR/$arch" ]; then
        echo "Copying libraries for $arch..."
        cp -v "$SRC_DIR/$arch"/*.so "$DEST_DIR/$arch/" 2>/dev/null || echo "  No libraries found for $arch"
    else
        echo "Skipping $arch (not built)"
    fi
done

echo ""
echo "Verifying required libraries..."
REQUIRED_LIBS="libmatrix_sdk_ffi.so libunomed-react-native-matrix-sdk.so libc++_shared.so libfbjni.so libjsi.so libreactnative.so"

for arch in arm64-v8a armeabi-v7a; do
    echo "Checking $arch:"
    for lib in $REQUIRED_LIBS; do
        if [ -f "$DEST_DIR/$arch/$lib" ]; then
            echo "  ✓ $lib"
        else
            echo "  ✗ $lib MISSING!"
        fi
    done
done

echo ""
echo "Library copy complete!"