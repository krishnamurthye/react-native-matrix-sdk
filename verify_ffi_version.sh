#!/bin/bash

echo "=========================================="
echo "FFI Library Version Verification"
echo "=========================================="
echo ""

# Check if the symbol exists in the library
echo "1. Checking for normal_sync symbols in native library:"
echo "   Location: android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so"

if nm -D android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so 2>/dev/null | grep -q "checksum_method_client_normal_sync"; then
    echo "   ✅ normal_sync checksum method found!"
    nm -D android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so 2>/dev/null | grep "normal_sync" | head -3
else
    echo "   ❌ normal_sync checksum method NOT found!"
fi

echo ""
echo "2. Library file info:"
ls -lh android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so
echo "   SHA256: $(sha256sum android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so | cut -d' ' -f1)"

echo ""
echo "3. Checking TypeScript bindings:"
if grep -q "normalSync" src/generated/matrix_sdk_ffi.ts 2>/dev/null; then
    echo "   ✅ normalSync method found in TypeScript!"
    grep -c "normalSync" src/generated/matrix_sdk_ffi.ts | xargs echo "   Found normalSync references:"
else
    echo "   ❌ normalSync method NOT found in TypeScript!"
fi

echo ""
echo "4. Checking if library is in example app (if built):"
EXAMPLE_LIB="example/android/app/build/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib/arm64-v8a/libmatrix_sdk_ffi.so"
if [ -f "$EXAMPLE_LIB" ]; then
    if nm -D "$EXAMPLE_LIB" 2>/dev/null | grep -q "checksum_method_client_normal_sync"; then
        echo "   ✅ Example app has updated library!"
    else
        echo "   ❌ Example app has OLD library (rebuild needed)!"
    fi
else
    echo "   ⚠️  Example app not built yet"
fi

echo ""
echo "=========================================="
echo "To ensure correct library is used:"
echo "1. Run: yarn generate:android"
echo "2. Clean example: cd example && ./android/gradlew -p android clean"
echo "3. Rebuild: cd example && npx react-native run-android"
echo "=========================================="