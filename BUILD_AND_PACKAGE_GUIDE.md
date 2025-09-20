# Build and Package Guide for React Native Matrix SDK

**Last Updated: 2025-09-20**

## 📦 Complete Build Process After Making Changes

When you make changes to this SDK (Rust code, FFI bindings, or TypeScript), follow these steps to build and package the binaries for app usage.

## Prerequisites

### Required Tools
```bash
# Check if installed
rustc --version          # Rust 1.70+
cargo --version          # Cargo
node --version           # Node.js 18+
yarn --version           # Yarn 3+
ubrn --version           # uniffi-bindgen-react-native

# Android specific
echo $ANDROID_NDK_HOME   # Android NDK path
echo $ANDROID_HOME       # Android SDK path

# iOS specific (macOS only)
xcodebuild -version      # Xcode
pod --version            # CocoaPods
```

### Install Missing Tools
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

# Install iOS targets (macOS only)
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

# Install uniffi-bindgen-react-native
npm install -g uniffi-bindgen-react-native@0.29.3-1

# Install yarn if needed
npm install -g yarn
```

## 🔨 Step-by-Step Build Process

### 1. Clean Previous Build
```bash
# Clean all generated files
yarn ubrn:clean

# Or clean platform-specific
yarn ubrn:clean:android
yarn ubrn:clean:ios
```

### 2. Apply Patches and Checkout
```bash
# This applies the matrix-rust-sdk.patch with VoIP support
yarn ubrn:checkout
```

### 3. Build for Android

#### Development Build
```bash
# Set Android NDK path (adjust for your system)
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125

# Build Android binaries with native bindings
yarn ubrn:android:build

# Or use the shorthand
yarn generate:android
```

#### Release Build (Optimized)
```bash
# Build optimized Android binaries
yarn generate:release:android
```

### 4. Build for iOS (macOS only)

#### Development Build
```bash
# Build iOS binaries
yarn ubrn:ios:build

# Post-process and generate Swift files
yarn ubrn:ios:post-process

# Or use the shorthand
yarn generate:ios
```

#### Release Build (Optimized)
```bash
# Build optimized iOS binaries
yarn generate:release:ios
```

### 5. Build for Both Platforms

#### Development Build
```bash
# Build for both Android and iOS
yarn generate
```

#### Release Build
```bash
# Build optimized binaries for both platforms
yarn generate:release
```

## 📋 File Structure After Build

After building, your directory structure should look like:

```
react-native-matrix-sdk/
├── android/
│   ├── src/main/java/          # Generated Java/Kotlin FFI bindings
│   │   ├── com/unomed/          # React Native module
│   │   └── org/matrix/          # Rust FFI bindings
│   └── src/main/jniLibs/       # Native .so libraries
│       ├── arm64-v8a/
│       ├── armeabi-v7a/
│       └── x86_64/
├── ios/
│   ├── generated/               # Generated iOS bindings
│   └── Frameworks/              # Native frameworks
├── cpp/
│   └── generated/               # Generated C++ bindings
├── src/
│   ├── generated/               # Generated TypeScript bindings
│   │   ├── matrix_sdk_ffi.ts
│   │   └── matrix_sdk_ffi-ffi.ts
│   └── index.tsx                # Main export file
└── package/                    # Packaged version for distribution
```

## 🚀 Creating NPM Package

### 1. Build the Package
```bash
# Ensure you have built the binaries first
yarn generate:release

# Prepare the package
yarn prepare

# Create the package tarball
cd package
npm pack
```

This creates: `unomed-react-native-matrix-sdk-0.7.0.tgz`

### 2. Package with Binaries
```bash
# Package binaries for GitHub release
node scripts/package-binaries.js

# This creates: binaries.tar.gz
```

## 📱 Using in Your App

### Local Development (Using Local Package)
```bash
# In your app directory
yarn add file:../react-native-matrix-sdk/package

# Or using the tarball
yarn add ../react-native-matrix-sdk/unomed-react-native-matrix-sdk-0.7.0.tgz
```

### From NPM Registry
```bash
yarn add @unomed/react-native-matrix-sdk
```

### iOS Additional Steps
```bash
cd ios
pod install
```

### Android Additional Steps
```bash
cd android
./gradlew clean
./gradlew assembleDebug
```

## 🔄 Workflow for Making Changes

### When You Modify Rust Code

**Date: 2025-09-20 - Example VoIP Implementation**

1. **Make changes to Rust code**
```bash
# Edit files in rust_modules/matrix-rust-sdk/
# For VoIP: Modified bindings/matrix-sdk-ffi/src/client.rs
```

2. **Rebuild bindings**
```bash
# Clean and rebuild
yarn ubrn:clean
yarn generate:release
```

3. **Test locally**
```bash
cd example
yarn install
yarn android  # or yarn ios
```

4. **Package for distribution**
```bash
npm pack
```

### When You Modify TypeScript Only

1. **Make TypeScript changes**
```bash
# Edit files in src/
```

2. **Rebuild TypeScript**
```bash
yarn prepare  # Runs bob build
```

3. **Test changes**
```bash
yarn typecheck
yarn lint
```

## 🐛 Common Issues and Solutions

### Issue: Android Build Fails with NDK Error
```bash
# Solution: Set correct NDK path
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125

# For Linux x86_64
export CARGO_TARGET_X86_64_LINUX_ANDROID_RUSTFLAGS="-L$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/17/lib/linux"

# For macOS
export CARGO_TARGET_X86_64_LINUX_ANDROID_RUSTFLAGS="-L$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/lib/clang/17/lib/linux"
```

### Issue: iOS Build Fails
```bash
# Solution: Clean and rebuild
cd ios
pod deintegrate
pod install
cd ..
yarn generate:ios
```

### Issue: Out of Memory During Build
```bash
# Increase Node memory
export NODE_OPTIONS="--max-old-space-size=8192"

# Build with fewer parallel jobs
cargo build --jobs 2
```

### Issue: TypeScript Types Not Updated
```bash
# Force regenerate all bindings
yarn ubrn:clean
yarn ubrn:checkout
yarn generate
yarn prepare
```

## 📊 Build Time Estimates

| Platform | Debug Build | Release Build | Binary Size |
|----------|------------|---------------|-------------|
| Android  | ~5-10 min  | ~15-20 min    | ~60-80 MB   |
| iOS      | ~10-15 min | ~20-30 min    | ~100-120 MB |
| Both     | ~15-25 min | ~35-50 min    | ~180-200 MB |

## 🎯 Quick Commands Reference

```bash
# Daily development workflow
yarn generate:android          # Quick Android build
yarn generate:ios              # Quick iOS build
yarn prepare                   # Rebuild TypeScript

# Before committing
yarn typecheck                 # Check types
yarn lint                      # Check code style
yarn generate:release          # Full release build

# Creating release
yarn generate:release          # Build optimized binaries
npm pack                       # Create package
node scripts/package-binaries.js  # Package binaries for GitHub
```

## 📅 Change Log Format

When documenting changes, use this format:

```markdown
## 2025-09-20 - VoIP Support Addition
- Modified: `matrix-rust-sdk.patch` - Added VoIP event handlers
- Added: `CallEventListener` interface support
- Added: `room.sendRaw()` for sending call events
- Built with: `yarn generate:release`
- Package version: 0.7.0
- Binary hash: [sha256 of binaries.tar.gz]
```

## 🔐 Verifying Build Integrity

```bash
# Generate checksums
shasum -a 256 binaries.tar.gz > binaries.sha256
shasum -a 256 unomed-react-native-matrix-sdk-*.tgz >> binaries.sha256

# Verify checksums
shasum -c binaries.sha256
```

## 📝 Notes

- Always test on both platforms after making changes
- Keep the `matrix-rust-sdk.patch` file updated
- Document any new dependencies in package.json
- Update version in package.json before release
- Tag releases in git: `git tag v0.7.0`

---

**Remember**: After any changes to Rust/FFI code, you must rebuild binaries for both platforms before the changes will work in apps!