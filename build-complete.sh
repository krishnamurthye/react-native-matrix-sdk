#!/bin/bash
set -e

echo "========================================="
echo "Complete Build Process for react-native-matrix-sdk"
echo "========================================="

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "rust_modules" ]; then
    echo "Error: Must run from react-native-matrix-sdk root directory"
    exit 1
fi

echo "Step 1: Cleaning previous builds..."
rm -rf android/build
rm -rf android/.cxx
rm -rf lib
yarn clean 2>/dev/null || true

echo "Step 2: Installing dependencies..."
yarn install

echo "Step 3: Setting Android NDK environment..."
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
export NDK_HOME=$ANDROID_NDK_HOME
echo "NDK_HOME set to: $NDK_HOME"

echo "Step 4: Generating Rust FFI bindings and libraries..."
yarn generate:release

echo "Step 5: Building native C++ JNI wrapper..."
echo "WARNING: This step requires gradle to be installed!"
echo "Options:"
echo "  1. Install gradle: sudo apt-get install gradle (Ubuntu/Debian)"
echo "  2. Download gradle: https://gradle.org/install/"
echo "  3. Use gradle wrapper from another Android project"
echo ""
echo "Attempting to build with gradle..."

cd android

# Try different gradle options
if command -v gradle &> /dev/null; then
    echo "Using system gradle..."
    gradle assembleRelease
elif [ -f "./gradlew" ]; then
    echo "Using gradle wrapper..."
    ./gradlew assembleRelease
else
    echo "ERROR: Gradle not found!"
    echo ""
    echo "MANUAL FIX REQUIRED:"
    echo "1. Install gradle: sudo apt-get install gradle"
    echo "2. Or download from: https://gradle.org/install/"
    echo "3. Then run: cd android && gradle assembleRelease"
    echo ""
    echo "After gradle build completes, run the copy-native-libs.sh script"
    exit 1
fi

cd ..

echo "Step 6: Copying native libraries to jniLibs..."
./copy-native-libs.sh

echo "Step 7: Building TypeScript/JavaScript..."
yarn prepare

echo "Step 8: Creating package..."
npm pack

echo "========================================="
echo "Build Complete!"
echo "Package created: unomed-react-native-matrix-sdk-0.7.0.tgz"
echo "========================================="