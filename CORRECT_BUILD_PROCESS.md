# Correct Build Process for react-native-matrix-sdk

## Current Situation
- **Source folder**: `/home/lalitha/workspace_rust/react-native-matrix-sdk`
- **Current folder**: `/home/lalitha/workspace_rust/temp/package` (extracted from incomplete .tgz)
- **Problem**: The .tgz was created without compiling native C++ libraries

## Correct Build Sequence (Run in Source Folder)

```bash
cd /home/lalitha/workspace_rust/react-native-matrix-sdk

# 1. Install dependencies
yarn install

# 2. Build TypeScript/JavaScript files
yarn prepare

# 3. Set Android NDK path
export ANDROID_NDK_HOME=/path/to/android-ndk
export NDK_HOME=$ANDROID_NDK_HOME  # Some tools use this

# 4. Generate Rust FFI bindings and libraries
yarn generate:release

# 5. ⚠️ MISSING STEP - Build C++ JNI wrapper
cd android
gradle assembleRelease  # or assembleDebug for debug build

# 6. Copy compiled native libraries to src/main/jniLibs
cd ..
mkdir -p android/src/main/jniLibs/arm64-v8a
mkdir -p android/src/main/jniLibs/armeabi-v7a
mkdir -p android/src/main/jniLibs/x86
mkdir -p android/src/main/jniLibs/x86_64

# Copy all .so files (including the JNI wrapper)
cp android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni/arm64-v8a/*.so \
   android/src/main/jniLibs/arm64-v8a/

cp android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni/armeabi-v7a/*.so \
   android/src/main/jniLibs/armeabi-v7a/

cp android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni/x86/*.so \
   android/src/main/jniLibs/x86/ 2>/dev/null || true

cp android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni/x86_64/*.so \
   android/src/main/jniLibs/x86_64/ 2>/dev/null || true

# 7. Create the package with all libraries included
npm pack
# This creates: unomed-react-native-matrix-sdk-0.7.0.tgz
```

## What Each Step Produces

| Step | Command | Output |
|------|---------|--------|
| 1 | yarn install | node_modules dependencies |
| 2 | yarn prepare | lib/ folder with JS files |
| 3 | export NDK | Sets environment for Rust compilation |
| 4 | yarn generate:release | `libmatrix_sdk_ffi.so` (Rust library) |
| 5 | gradle assembleRelease | `libunomed-react-native-matrix-sdk.so` (C++ JNI wrapper) + other libs |
| 6 | cp commands | All .so files in android/src/main/jniLibs |
| 7 | npm pack | Complete .tgz with all libraries |

## Required Libraries in android/src/main/jniLibs/

After step 6, you should have:

```
android/src/main/jniLibs/
├── arm64-v8a/
│   ├── libmatrix_sdk_ffi.so         # Rust FFI (from step 4)
│   ├── libunomed-react-native-matrix-sdk.so  # C++ JNI wrapper (from step 5)
│   ├── libjsi.so                    # React Native JSI
│   ├── libreactnative.so            # React Native core
│   ├── libfbjni.so                  # Facebook JNI
│   └── libc++_shared.so             # C++ standard library
└── armeabi-v7a/
    └── (same 6 files)
```

## Quick Fix for Current Package

If you want to fix the current extracted package without rebuilding:

```bash
# From /home/lalitha/workspace_rust/temp/package
cp -r ~/workspace_rust/@unomed/react-native-matrix-sdk/android/build/intermediates/library_jni/debug/copyDebugJniLibsProjectOnly/jni/* \
      android/src/main/jniLibs/
```

But it's better to rebuild properly from the source folder.

## Automated Build Script

Create this script in the source folder as `build-release.sh`:

```bash
#!/bin/bash
set -e

echo "Building react-native-matrix-sdk..."

# Clean previous builds
yarn clean

# Install dependencies
yarn install

# Build TypeScript
yarn prepare

# Generate Rust bindings
yarn generate:release

# Build Android native libraries
echo "Building Android native libraries..."
cd android
gradle assembleRelease
cd ..

# Copy native libraries
echo "Copying native libraries..."
for arch in arm64-v8a armeabi-v7a x86 x86_64; do
  mkdir -p android/src/main/jniLibs/$arch
  if [ -d "android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni/$arch" ]; then
    cp android/build/intermediates/library_jni/release/copyReleaseJniLibsProjectOnly/jni/$arch/*.so \
       android/src/main/jniLibs/$arch/ 2>/dev/null || true
  fi
done

# Verify libraries
echo "Verifying libraries..."
for lib in libmatrix_sdk_ffi.so libunomed-react-native-matrix-sdk.so; do
  if [ ! -f "android/src/main/jniLibs/arm64-v8a/$lib" ]; then
    echo "ERROR: Missing $lib"
    exit 1
  fi
done

# Create package
echo "Creating package..."
npm pack

echo "Build complete! Package created."
```

## Why This Wasn't Documented

The missing step (gradle build) is usually handled automatically when:
1. Building the example app
2. Building the consuming app
3. Using React Native's autolinking

But when creating a standalone package for distribution, you need to explicitly build and include the native libraries.