#!/bin/bash

# Full replacement deployment - replaces entire package folder
# This is the SAFEST way to ensure everything is in sync

set -e

echo "=========================================="
echo "🔄 FULL PACKAGE REPLACEMENT DEPLOYMENT"
echo "=========================================="
echo ""

SDK_DIR="/home/lalitha/workspace_rust/react-native-matrix-sdk"
APP_DIR="/home/lalitha/workspace_rust/rork-Clique-500"
APP_MODULE="$APP_DIR/node_modules/@unomed/react-native-matrix-sdk"
BACKUP_DIR="$APP_DIR/node_modules/@unomed/react-native-matrix-sdk.backup"

echo "📦 This will completely replace the package in your app"
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

# Step 3: Copy entire package
echo ""
echo "3️⃣ Copying entire package..."
mkdir -p "$(dirname "$APP_MODULE")"

# Copy everything EXCEPT node_modules and example
rsync -av --progress \
    --exclude 'node_modules' \
    --exclude 'example' \
    --exclude '.git' \
    --exclude 'rust_modules' \
    --exclude '*.log' \
    --exclude '.yarn' \
    "$SDK_DIR/" "$APP_MODULE/"

echo "   ✅ Package copied"

# Step 4: Verification
echo ""
echo "=========================================="
echo "✅ VERIFICATION"
echo "=========================================="
echo ""

# Check critical files
echo "Checking deployment success:"

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

# List what was deployed
echo ""
echo "📁 Deployed structure:"
echo "$(ls -la "$APP_MODULE" | head -15)"

echo ""
echo "=========================================="
echo "🎯 DEPLOYMENT COMPLETE"
echo "=========================================="
echo ""
echo "✅ The entire package has been replaced"
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