#!/bin/bash

# Build script for traditional sync support in React Native Matrix SDK
# This script builds the Rust FFI library with traditional sync support enabled

set -e  # Exit on error

echo "=========================================="
echo "Building React Native Matrix SDK with Traditional Sync Support"
echo "=========================================="
echo ""

# Navigate to the project directory
PROJECT_DIR="/home/lalitha/workspace_rust/react-native-matrix-sdk"
cd "$PROJECT_DIR"

echo "📍 Working directory: $(pwd)"
echo ""

# Check if rust_modules directory exists
if [ ! -d "rust_modules/matrix-rust-sdk" ]; then
    echo "❌ Error: rust_modules/matrix-rust-sdk directory not found!"
    echo "Please ensure you're in the correct project directory."
    exit 1
fi

# Build the Rust FFI library
echo "🔨 Building Rust FFI library with traditional sync support..."
echo "  This may take several minutes on first build..."
echo ""

cd rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi

# Clean previous builds (optional, uncomment if needed)
# cargo clean

# Build in release mode for better performance with rustls-tls feature
cargo build --release --features rustls-tls

if [ $? -eq 0 ]; then
    echo "✅ Rust build completed successfully!"
else
    echo "❌ Rust build failed!"
    exit 1
fi

# Return to project root
cd "$PROJECT_DIR"

# Generate TypeScript bindings
echo ""
echo "📝 Generating TypeScript bindings..."
if command -v yarn &> /dev/null; then
    yarn generate
    
    if [ $? -eq 0 ]; then
        echo "✅ TypeScript bindings generated successfully!"
    else
        echo "❌ TypeScript binding generation failed!"
        exit 1
    fi
else
    echo "⚠️  Yarn not found, skipping TypeScript generation"
    echo "   Run 'yarn generate' manually"
fi

# Build the complete package
echo ""
echo "📦 Building complete package..."
if command -v yarn &> /dev/null; then
    yarn build
    
    if [ $? -eq 0 ]; then
        echo "✅ Package build completed successfully!"
    else
        echo "❌ Package build failed!"
        exit 1
    fi
else
    echo "⚠️  Yarn not found, skipping package build"
    echo "   Run 'yarn build' manually"
fi

echo ""
echo "=========================================="
echo "✅ Build complete! Traditional sync support has been added."
echo "=========================================="

# Optional: Deploy to app
if [ -d "/home/lalitha/workspace_rust/rork-Clique-500" ]; then
    echo ""
    echo "📋 Deploying to rork-Clique-500 app..."
    APP_NODE_MODULES="/home/lalitha/workspace_rust/rork-Clique-500/node_modules/@unomed/react-native-matrix-sdk"
    
    if [ -d "$APP_NODE_MODULES" ]; then
        cp -r android/src/main/jniLibs/* "$APP_NODE_MODULES/android/src/main/jniLibs/"
        cp -r src/* "$APP_NODE_MODULES/src/"
        echo "✅ Deployed to app's node_modules"
    else
        echo "⚠️  App's node_modules not found, skipping deployment"
    fi
fi

echo ""
echo "=========================================="
echo ""
echo "📖 Usage example:"
echo ""
echo "  // Disable sliding sync to use traditional sync"
echo "  const client = await new ClientBuilder()"
echo "    .homeserverUrl('https://your-server.com')"
echo "    .slidingSyncVersionBuilder(SlidingSyncVersionBuilder.None)"
echo "    .build();"
echo ""
echo "  // Get the normal sync manager"
echo "  const normalSync = client.normalSync();"
echo ""
echo "  // Perform a single sync"
echo "  const nextBatch = await normalSync.syncOnce(30000, null);"
echo ""
echo "  // Or sync with configuration"
echo "  const config = {"
echo "    timeout_ms: 30000,"
echo "    full_state: false,"
echo "    set_presence: 'online'"
echo "  };"
echo "  const result = await normalSync.syncWithConfig(config);"
echo ""
echo "For more examples, see:"
echo "  - example/src/TraditionalSyncExample.tsx"
echo "  - example/src/UniversalSyncClient.ts"
echo ""