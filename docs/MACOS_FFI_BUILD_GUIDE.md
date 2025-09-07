# macOS FFI Build Guide for React Native Matrix SDK

This guide explains how to build the FFI (Foreign Function Interface) bindings when moving to a MacBook, particularly for Intel-based Macs.

## Prerequisites

### 1. Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### 2. Install Required Rust Targets
```bash
# For Intel Mac (x86_64)
rustup target add x86_64-apple-darwin

# For Apple Silicon (if needed later)
rustup target add aarch64-apple-darwin

# For iOS development (optional)
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios  # iOS simulator on Intel
```

### 3. Install Android NDK (for Android development)
```bash
# Install via Android Studio or:
brew install --cask android-ndk

# Set environment variables in ~/.zshrc or ~/.bash_profile
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.2.9519653  # Check your version
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### 4. Install cargo-ndk for Android builds
```bash
cargo install cargo-ndk
```

## Building the FFI

### Clone and Setup

```bash
# Clone your fork
git clone git@github.com:krishnamurthye/react-native-matrix-sdk.git
cd react-native-matrix-sdk
git checkout normalsync

# Install dependencies
yarn install
```

### Build for Android Only (Initial Focus)

```bash
# Navigate to the rust modules
cd rust_modules/matrix-rust-sdk

# Build for Android architectures
cargo ndk \
  -t arm64-v8a \
  -t x86_64 \
  -o ../../android/src/main/jniLibs \
  build --release --features rustls-tls

# The built libraries will be at:
# - android/src/main/jniLibs/arm64-v8a/libmatrix_sdk_ffi.so
# - android/src/main/jniLibs/x86_64/libmatrix_sdk_ffi.so
```

### Generate TypeScript Bindings

```bash
# From the root of react-native-matrix-sdk
yarn generate:android

# This will:
# 1. Build the Rust FFI library for Android
# 2. Generate TypeScript bindings
# 3. Copy files to the correct locations
```

### Quick Build Script

Create a file `build_android.sh`:

```bash
#!/bin/bash
set -e

echo "🔨 Building Matrix SDK FFI for Android..."

# Navigate to rust modules
cd rust_modules/matrix-rust-sdk

# Clean previous builds
cargo clean

# Build for Android
echo "📱 Building for Android (arm64-v8a, x86_64)..."
cargo ndk \
  -t arm64-v8a \
  -t x86_64 \
  -o ../../android/src/main/jniLibs \
  build --release --features rustls-tls

echo "✅ Build complete!"

# Generate bindings
cd ../..
echo "🔄 Generating TypeScript bindings..."
yarn generate:android

echo "🎉 All done! Libraries ready for Android development"
```

Make it executable:
```bash
chmod +x build_android.sh
```

## Troubleshooting

### 1. "cargo-ndk not found"
```bash
cargo install cargo-ndk
```

### 2. "NDK not found"
Ensure `ANDROID_NDK_HOME` is set correctly:
```bash
echo $ANDROID_NDK_HOME
# Should output something like: /Users/yourname/Library/Android/sdk/ndk/25.2.9519653
```

### 3. Build fails with "can't find crate"
```bash
# Update dependencies
cd rust_modules/matrix-rust-sdk
cargo update
```

### 4. TypeScript bindings not generating
```bash
# Install uniffi-bindgen-react-native globally
npm install -g uniffi-bindgen-react-native

# Or use npx
npx uniffi-bindgen-react-native generate \
  --module-name matrix_sdk_ffi \
  --kotlin
```

## Testing the Build

After building, test in your app:

```bash
# In your React Native app directory
cd /path/to/your/app

# Install the local package
yarn add file:../react-native-matrix-sdk

# Run on Android
npx react-native run-android
```

## Architecture Support

For Android development on macOS:
- **arm64-v8a**: Required for modern Android devices
- **x86_64**: Required for Android emulator on Intel Mac
- **armeabi-v7a**: Optional, for older 32-bit devices (excluded to save build time)

## Next Steps for iOS (Future)

When ready to support iOS:

```bash
# Build for iOS
cargo build --target x86_64-apple-ios --release
cargo build --target aarch64-apple-ios --release

# Create universal binary
cargo lipo --release --targets aarch64-apple-ios,x86_64-apple-ios
```

## Important Notes

1. **Initial Focus**: Start with Android-only development to simplify the build process
2. **Build Time**: Excluding unnecessary architectures (like armeabi-v7a) significantly reduces build time
3. **Local Development**: Use `file:` protocol in package.json to test local changes quickly
4. **Version Control**: Always commit your Cargo.lock file for reproducible builds

## Quick Commands Reference

```bash
# Clean build
cargo clean && yarn build

# Build Android only
yarn generate:android

# Run type checking
yarn typecheck

# Run linting
yarn lint

# Full rebuild
rm -rf node_modules android/build ios/build
yarn install
yarn generate:android
```

## Support

For issues specific to the normal sync implementation:
- Check the [normalsync branch](https://github.com/krishnamurthye/react-native-matrix-sdk/tree/normalsync)
- Review [TRADITIONAL_SYNC_SETUP.md](./TRADITIONAL_SYNC_SETUP.md)
- See [example_sync_implementation.ts](./example_sync_implementation.ts) for usage patterns