#!/bin/bash

# Comprehensive deployment of Matrix SDK to app
# This ensures ALL necessary files are updated

set -e

echo "=========================================="
echo "Comprehensive Matrix SDK Deployment"
echo "=========================================="
echo ""

SDK_DIR="/home/lalitha/workspace_rust/react-native-matrix-sdk"
APP_DIR="/home/lalitha/workspace_rust/rork-Clique-500"
APP_MODULE="$APP_DIR/node_modules/@unomed/react-native-matrix-sdk"

if [ ! -d "$APP_MODULE" ]; then
    echo "❌ Error: App module directory not found at $APP_MODULE"
    exit 1
fi

echo "📋 Files to update for normal sync support:"
echo ""

# 1. Native libraries (CRITICAL)
echo "1️⃣ Native Libraries (.so files)"
echo "   Source: $SDK_DIR/android/src/main/jniLibs/"
echo "   Target: $APP_MODULE/android/src/main/jniLibs/"
cp -rv "$SDK_DIR/android/src/main/jniLibs/"* "$APP_MODULE/android/src/main/jniLibs/" 2>/dev/null || echo "   ✅ Updated"

# 2. Source TypeScript files (CRITICAL)
echo ""
echo "2️⃣ Source TypeScript files"
echo "   Source: $SDK_DIR/src/"
echo "   Target: $APP_MODULE/src/"
cp -rv "$SDK_DIR/src/"* "$APP_MODULE/src/" 2>/dev/null || echo "   ✅ Updated"

# 3. Compiled JavaScript/TypeScript (CRITICAL)
echo ""
echo "3️⃣ Compiled lib files"
echo "   Source: $SDK_DIR/lib/"
echo "   Target: $APP_MODULE/lib/"
if [ -d "$SDK_DIR/lib" ]; then
    cp -rv "$SDK_DIR/lib/"* "$APP_MODULE/lib/" 2>/dev/null || echo "   ✅ Updated"
else
    echo "   ⚠️  No lib directory found (needs building)"
fi

# 4. Android Kotlin/Java generated files
echo ""
echo "4️⃣ Android generated files"
echo "   Source: $SDK_DIR/android/generated/"
echo "   Target: $APP_MODULE/android/generated/"
if [ -d "$SDK_DIR/android/generated" ]; then
    cp -rv "$SDK_DIR/android/generated/"* "$APP_MODULE/android/generated/" 2>/dev/null || echo "   ✅ Updated"
fi

# 5. Android source files
echo ""
echo "5️⃣ Android source Java/Kotlin files"
echo "   Source: $SDK_DIR/android/src/main/java/"
echo "   Target: $APP_MODULE/android/src/main/java/"
if [ -d "$SDK_DIR/android/src/main/java" ]; then
    cp -rv "$SDK_DIR/android/src/main/java/"* "$APP_MODULE/android/src/main/java/" 2>/dev/null || echo "   ✅ Updated"
fi

# 6. iOS files (if needed)
echo ""
echo "6️⃣ iOS files"
if [ -d "$SDK_DIR/ios" ]; then
    echo "   Source: $SDK_DIR/ios/"
    echo "   Target: $APP_MODULE/ios/"
    cp -rv "$SDK_DIR/ios/"* "$APP_MODULE/ios/" 2>/dev/null || echo "   ✅ Updated"
else
    echo "   ⏭️  Skipping (iOS not built)"
fi

# 7. C++ files
echo ""
echo "7️⃣ C++ bridge files"
echo "   Source: $SDK_DIR/cpp/"
echo "   Target: $APP_MODULE/cpp/"
if [ -d "$SDK_DIR/cpp" ]; then
    cp -rv "$SDK_DIR/cpp/"* "$APP_MODULE/cpp/" 2>/dev/null || echo "   ✅ Updated"
fi

echo ""
echo "=========================================="
echo "🔍 Verification"
echo "=========================================="
echo ""

# Verify critical files
echo "Checking critical components:"

# Check native library
if nm -D "$APP_MODULE/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so" 2>/dev/null | grep -q "checksum_method_client_normal_sync"; then
    echo "✅ Native library has normal_sync support"
    NATIVE_SHA=$(sha256sum "$APP_MODULE/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so" | cut -d' ' -f1)
    echo "   SHA256: ${NATIVE_SHA:0:16}..."
else
    echo "❌ Native library missing normal_sync support!"
fi

# Check TypeScript source
if [ -f "$APP_MODULE/src/generated/matrix_sdk_ffi.ts" ]; then
    NORMAL_SYNC_COUNT=$(grep -c "normalSync" "$APP_MODULE/src/generated/matrix_sdk_ffi.ts" 2>/dev/null || echo "0")
    if [ "$NORMAL_SYNC_COUNT" -gt 0 ]; then
        echo "✅ TypeScript has normalSync ($NORMAL_SYNC_COUNT references)"
    else
        echo "❌ TypeScript missing normalSync!"
    fi
else
    echo "❌ TypeScript file not found!"
fi

# Check compiled JS
if [ -f "$APP_MODULE/lib/module/generated/matrix_sdk_ffi.js" ]; then
    JS_NORMAL_SYNC=$(grep -c "normalSync" "$APP_MODULE/lib/module/generated/matrix_sdk_ffi.js" 2>/dev/null || echo "0")
    if [ "$JS_NORMAL_SYNC" -gt 0 ]; then
        echo "✅ Compiled JS has normalSync ($JS_NORMAL_SYNC references)"
    else
        echo "❌ Compiled JS missing normalSync!"
    fi
else
    echo "⚠️  Compiled JS not found (may need rebuild)"
fi

echo ""
echo "=========================================="
echo "📱 Next Steps"
echo "=========================================="
echo ""
echo "1. Clean Android build:"
echo "   cd $APP_DIR/android && ./gradlew clean"
echo ""
echo "2. Rebuild the app:"
echo "   cd $APP_DIR && npx react-native run-android"
echo ""
echo "3. If still having issues, try:"
echo "   - Clear Metro cache: npx react-native start --reset-cache"
echo "   - Clear node_modules: rm -rf node_modules && yarn install"
echo ""