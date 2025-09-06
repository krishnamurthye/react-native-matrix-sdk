#!/bin/bash

# Deploy Matrix SDK with Normal Sync to App
# This script builds the FFI, generates bindings, and deploys to the app

set -e

echo "=========================================="
echo "Building and Deploying Matrix SDK with Normal Sync"
echo "=========================================="
echo ""

# Configuration
SDK_DIR="/home/lalitha/workspace_rust/react-native-matrix-sdk"
APP_DIR="/home/lalitha/workspace_rust/rork-Clique-500"
APP_NODE_MODULES="$APP_DIR/node_modules/@unomed/react-native-matrix-sdk"

# Step 1: Build the FFI library
echo "📦 Step 1: Building FFI library with normal_sync..."
cd "$SDK_DIR"
cd rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi
cargo build --release --features rustls-tls

# Step 2: Generate Android bindings
echo ""
echo "🤖 Step 2: Generating Android bindings..."
cd "$SDK_DIR"
yarn generate:android

# Step 3: Prepare the package (if needed)
echo ""
echo "📝 Step 3: Preparing package..."
# yarn prepare would normally do this, but let's do it manually

# Step 4: Copy to app's node_modules
echo ""
echo "📋 Step 4: Deploying to app's node_modules..."

# Copy native libraries
echo "   Copying native libraries..."
cp -r "$SDK_DIR/android/src/main/jniLibs/"* "$APP_NODE_MODULES/android/src/main/jniLibs/"

# Copy TypeScript/JavaScript files
echo "   Copying TypeScript bindings..."
cp -r "$SDK_DIR/src/"* "$APP_NODE_MODULES/src/"

# Copy lib files if they exist
if [ -d "$SDK_DIR/lib" ]; then
    echo "   Copying lib files..."
    cp -r "$SDK_DIR/lib/"* "$APP_NODE_MODULES/lib/" 2>/dev/null || true
fi

# Step 5: Verify deployment
echo ""
echo "✅ Step 5: Verifying deployment..."

# Check for normal_sync in native library
if nm -D "$APP_NODE_MODULES/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so" 2>/dev/null | grep -q "checksum_method_client_normal_sync"; then
    echo "   ✅ Native library has normal_sync support"
else
    echo "   ❌ Native library missing normal_sync support!"
    exit 1
fi

# Check for normalSync in TypeScript
if grep -q "normalSync" "$APP_NODE_MODULES/src/generated/matrix_sdk_ffi.ts" 2>/dev/null; then
    echo "   ✅ TypeScript bindings have normalSync method"
else
    echo "   ❌ TypeScript bindings missing normalSync method!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Library checksums:"
echo "arm64-v8a: $(sha256sum $APP_NODE_MODULES/android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so | cut -d' ' -f1)"
echo ""
echo "Next steps:"
echo "1. cd $APP_DIR"
echo "2. cd android && ./gradlew clean"
echo "3. cd .. && npx react-native run-android"
echo ""