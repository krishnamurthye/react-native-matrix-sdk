#!/bin/bash

# Clean deployment - only copies necessary runtime files
# Excludes all build scripts and development files

set -e

echo "=========================================="
echo "🧹 CLEAN PACKAGE DEPLOYMENT"
echo "=========================================="
echo ""

SDK_DIR="/home/lalitha/workspace_rust/react-native-matrix-sdk"
APP_DIR="/home/lalitha/workspace_rust/rork-Clique-500"
APP_MODULE="$APP_DIR/node_modules/@unomed/react-native-matrix-sdk"
BACKUP_DIR="$APP_DIR/node_modules/@unomed/react-native-matrix-sdk.backup"

echo "📦 This will deploy only necessary runtime files"
echo "   Source: $SDK_DIR"
echo "   Target: $APP_MODULE"
echo ""

# Step 1: Create backup
echo "1️⃣ Creating backup..."
if [ -d "$APP_MODULE" ]; then
    rm -rf "$BACKUP_DIR" 2>/dev/null || true
    cp -r "$APP_MODULE" "$BACKUP_DIR"
    echo "   ✅ Backup created at: $BACKUP_DIR"
else
    echo "   ⚠️  No existing module to backup"
fi

# Step 2: Remove old module completely
echo ""
echo "2️⃣ Removing old module..."
if [ -d "$APP_MODULE" ]; then
    rm -rf "$APP_MODULE"
    echo "   ✅ Old module removed"
fi

# Step 3: Create directory structure
echo ""
echo "3️⃣ Creating clean package structure..."
mkdir -p "$APP_MODULE"

# Step 4: Copy only necessary files
echo ""
echo "4️⃣ Copying runtime files..."

# Package files
cp "$SDK_DIR/package.json" "$APP_MODULE/"
cp "$SDK_DIR/README.md" "$APP_MODULE/" 2>/dev/null || true

# Android native libraries and files
echo "   Copying Android files..."
mkdir -p "$APP_MODULE/android"
cp -r "$SDK_DIR/android/src" "$APP_MODULE/android/"
cp -r "$SDK_DIR/android/generated" "$APP_MODULE/android/" 2>/dev/null || true
cp "$SDK_DIR/android/build.gradle" "$APP_MODULE/android/"
cp "$SDK_DIR/android/gradle.properties" "$APP_MODULE/android/" 2>/dev/null || true

# iOS files (if they exist)
if [ -d "$SDK_DIR/ios" ]; then
    echo "   Copying iOS files..."
    cp -r "$SDK_DIR/ios" "$APP_MODULE/"
fi

# Source TypeScript files
echo "   Copying TypeScript source..."
cp -r "$SDK_DIR/src" "$APP_MODULE/"

# Compiled JavaScript (if exists)
if [ -d "$SDK_DIR/lib" ]; then
    echo "   Copying compiled JavaScript..."
    cp -r "$SDK_DIR/lib" "$APP_MODULE/"
fi

# C++ bridge files (if needed)
if [ -d "$SDK_DIR/cpp" ]; then
    echo "   Copying C++ bridge..."
    cp -r "$SDK_DIR/cpp" "$APP_MODULE/"
fi

# Config files needed for the package
for file in tsconfig.json react-native-matrix-sdk.podspec; do
    if [ -f "$SDK_DIR/$file" ]; then
        cp "$SDK_DIR/$file" "$APP_MODULE/"
    fi
done

echo "   ✅ Runtime files copied"

# Step 5: Verification
echo ""
echo "=========================================="
echo "✅ VERIFICATION"
echo "=========================================="
echo ""

# Check critical files
echo "Checking deployment:"

# Native library check
if [ -f "$APP_MODULE/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so" ]; then
    if nm -D "$APP_MODULE/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so" 2>/dev/null | grep -q "checksum_method_client_normal_sync"; then
        echo "✅ Native library: Has normal_sync support"
        LIB_SIZE=$(ls -lh "$APP_MODULE/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so" | awk '{print $5}')
        echo "   Size: $LIB_SIZE"
    else
        echo "❌ Native library: Missing normal_sync support!"
    fi
else
    echo "❌ Native library not found!"
fi

# TypeScript check
if [ -f "$APP_MODULE/src/generated/matrix_sdk_ffi.ts" ]; then
    NORMAL_SYNC_COUNT=$(grep -c "normalSync" "$APP_MODULE/src/generated/matrix_sdk_ffi.ts" 2>/dev/null || echo "0")
    echo "✅ TypeScript: Has normalSync ($NORMAL_SYNC_COUNT references)"
else
    echo "❌ TypeScript file not found!"
fi

# Package.json check
if [ -f "$APP_MODULE/package.json" ]; then
    PACKAGE_NAME=$(grep '"name"' "$APP_MODULE/package.json" | head -1)
    echo "✅ Package.json: $PACKAGE_NAME"
else
    echo "❌ Package.json not found!"
fi

# Check what's NOT in the deployed package (should be excluded)
echo ""
echo "📁 Excluded files check:"
[ ! -f "$APP_MODULE/build_traditional_sync.sh" ] && echo "✅ Build scripts excluded" || echo "❌ Build scripts present"
[ ! -d "$APP_MODULE/rust_modules" ] && echo "✅ Rust modules excluded" || echo "❌ Rust modules present"
[ ! -d "$APP_MODULE/.git" ] && echo "✅ Git directory excluded" || echo "❌ Git directory present"
[ ! -f "$APP_MODULE/deploy_matrix_sdk.sh" ] && echo "✅ Deploy scripts excluded" || echo "❌ Deploy scripts present"

echo ""
echo "=========================================="
echo "🎯 CLEAN DEPLOYMENT COMPLETE"
echo "=========================================="
echo ""
echo "✅ Only runtime files have been deployed"
echo "📋 Backup saved at: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. cd $APP_DIR"
echo "2. cd android && ./gradlew clean && cd .."
echo "3. npx react-native run-android"
echo ""
echo "To restore backup if needed:"
echo "   rm -rf $APP_MODULE && mv $BACKUP_DIR $APP_MODULE"
echo ""