# Proper Build Solution for react-native-matrix-sdk

## Problem Summary

The current build process (`yarn generate`) is incomplete because it:
- ✅ Builds the Rust FFI library (`libmatrix_sdk_ffi.so`)
- ❌ Does NOT build the C++ JNI wrapper (`libunomed-react-native-matrix-sdk.so`)
- ❌ Does NOT include React Native bridge libraries

## The Missing Step

The critical missing step is running gradle to build the C++ JNI wrapper that bridges React Native's JavaScript to the Rust code.

## Complete Build Process

### Prerequisites

1. **Install Gradle** (required for building C++ JNI wrapper):
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install gradle

   # Or download from https://gradle.org/install/
   ```

2. **Android NDK** (already configured):
   ```bash
   export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
   ```

### Build Steps

```bash
# 1. Clean previous builds
yarn clean
rm -rf android/build android/.cxx

# 2. Install dependencies
yarn install

# 3. Generate Rust FFI bindings
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
yarn generate:release

# 4. Build C++ JNI wrapper (THE MISSING STEP!)
cd android
gradle assembleRelease  # or assembleDebug for debug build
cd ..

# 5. Copy all native libraries to jniLibs
chmod +x copy-native-libs.sh
./copy-native-libs.sh release

# 6. Build TypeScript/JavaScript
yarn prepare

# 7. Create package
npm pack
```

## What Each Step Produces

| Step | Command | Creates |
|------|---------|---------|
| 3 | yarn generate:release | `libmatrix_sdk_ffi.so` (Rust library) |
| 4 | gradle assembleRelease | `libunomed-react-native-matrix-sdk.so` (C++ JNI wrapper) + React Native libraries |
| 5 | copy-native-libs.sh | Copies all .so files to `android/src/main/jniLibs/` |
| 6 | yarn prepare | JavaScript files in `lib/` |
| 7 | npm pack | Complete .tgz package |

## Required Libraries

After the build, `android/src/main/jniLibs/` should contain:

### For each architecture (arm64-v8a, armeabi-v7a):
1. `libmatrix_sdk_ffi.so` - Rust FFI library with VoIP support
2. `libunomed-react-native-matrix-sdk.so` - C++ JNI wrapper (bridges JS to Rust)
3. `libc++_shared.so` - C++ standard library
4. `libfbjni.so` - Facebook JNI utilities
5. `libjsi.so` - React Native JSI bridge
6. `libreactnative.so` - React Native core

## Why Copying from Working Directory is Wrong

Copying pre-built binaries from another directory is problematic because:

1. **Version Mismatch**: The binaries might be from a different version
2. **Architecture Issues**: They might be compiled for different architectures
3. **Missing VoIP**: The old binaries don't have the new VoIP functionality
4. **Dependency Hell**: Different NDK/compiler versions can cause crashes
5. **Not Reproducible**: Can't rebuild from source

## Automated Build Script

Use the provided `build-complete.sh` script:

```bash
chmod +x build-complete.sh
./build-complete.sh
```

This script will:
1. Clean previous builds
2. Install dependencies
3. Generate Rust FFI
4. Build C++ JNI wrapper (requires gradle)
5. Copy native libraries
6. Build TypeScript
7. Create package

## Verification

After building, verify all libraries are present:

```bash
ls -la android/src/main/jniLibs/arm64-v8a/
```

Should show:
```
libmatrix_sdk_ffi.so         (150+ MB - includes VoIP)
libunomed-react-native-matrix-sdk.so (90+ MB)
libc++_shared.so             (~1.8 MB)
libfbjni.so                  (~2.1 MB)
libjsi.so                    (~4.8 MB)
libreactnative.so            (~165 MB)
```

## Installing Gradle

If gradle is not installed:

### Option 1: Package Manager
```bash
# Ubuntu/Debian
sudo apt-get install gradle

# Fedora
sudo dnf install gradle

# macOS
brew install gradle
```

### Option 2: Manual Installation
```bash
# Download Gradle
wget https://services.gradle.org/distributions/gradle-8.3-bin.zip

# Extract
unzip gradle-8.3-bin.zip

# Add to PATH
export PATH=$PATH:$(pwd)/gradle-8.3/bin

# Verify
gradle --version
```

### Option 3: Use Android Studio's Gradle
If you have Android Studio installed, it includes gradle. Add it to your PATH:
```bash
export PATH=$PATH:$HOME/Android/Studio/gradle/gradle-8.3/bin
```

## Troubleshooting

### Error: "Gradle not found"
Install gradle using one of the methods above.

### Error: "NDK not found"
Set the NDK path:
```bash
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
```

### Error: "CMake not found"
Install CMake:
```bash
sudo apt-get install cmake
```

### Libraries not copying
Make sure the gradle build completed successfully before running copy-native-libs.sh

## Summary

The key insight is that `yarn generate` only builds the Rust part, but a React Native module with native code needs the C++ JNI wrapper built by gradle. This wrapper is what allows JavaScript to communicate with the native Rust code.

Without the gradle build step, you only have half of what's needed for the module to work.