# ✅ Working Build Process - Complete VoIP Matrix SDK

**Last Successful Build:** September 20, 2025
**Package Created:** `unomed-react-native-matrix-sdk-0.7.0.tgz` (166MB with native libraries)
**VoIP Status:** ✅ Working - Event handlers properly implemented

## 🎯 The Working Command Sequence

This is the **exact sequence** that successfully built the complete package with VoIP support:

```bash
# Step 1: Run the release build command
yarn generate:release:android

# Step 2: Sort uniffi initialization calls (automatically done by above)
# node scripts/sort-uniffi-calls.js (already included)

# Step 3: Package the npm module
npm pack
```

**Result:** Creates `unomed-react-native-matrix-sdk-0.7.0.tgz` with working VoIP support.

## 🔍 What `yarn generate:release:android` Actually Does

Breaking down the successful command:

```bash
yarn generate:release:android
```

**This command internally runs:**
1. `yarn ubrn:clean:android` - Clean Android-specific artifacts
2. `yarn ubrn:checkout` - Checkout matrix-rust-sdk AND apply VoIP patch
3. `yarn ubrn:android:build:release --and-generate` - Build Rust libraries + generate bindings
4. `node scripts/sort-uniffi-calls.js` - Sort uniffi initialization order

## 📋 Detailed Step Breakdown

### Step 1: Clean Android Artifacts
```bash
yarn ubrn:clean:android
# Removes: android/src/main/java, src/Native*, src/generated, src/index.ts*
```

### Step 2: Checkout SDK and Apply VoIP Patch
```bash
yarn ubrn:checkout
# This does:
# 1. git -C rust_modules/matrix-rust-sdk reset --hard HEAD (if exists)
# 2. ubrn checkout --config ubrn.yaml (downloads matrix-rust-sdk)
# 3. cd rust_modules/matrix-rust-sdk && git apply ../../matrix-rust-sdk.patch
```

**🔑 KEY SUCCESS FACTOR:** The `matrix-rust-sdk.patch` contains ALL VoIP fixes:
- VoIP event imports in client.rs
- `add_call_event_listener` method implementation
- Complete voip.rs file with traits and types

### Step 3: Build Rust Libraries + Generate Bindings
```bash
yarn ubrn:android:build:release --and-generate
# This does:
# 1. Builds Rust code for Android (arm64-v8a, armeabi-v7a)
# 2. Generates Java/Kotlin FFI bindings
# 3. Generates TypeScript bindings
# 4. Copies libraries to android/src/main/jniLibs/
```

**Build targets:**
- `arm64-v8a/libmatrix_sdk_ffi.so` (97MB)
- `armeabi-v7a/libmatrix_sdk_ffi.so` (69MB)

### Step 4: Sort Uniffi Calls
```bash
node scripts/sort-uniffi-calls.js
# Ensures proper initialization order:
# matrix_sdk → matrix_sdk_base → matrix_sdk_common → matrix_sdk_crypto → matrix_sdk_ui
```

## 🛠️ Environment Requirements

### Required Environment Variables
```bash
# Android NDK (critical for build)
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125

# For Linux x86_64 hosts
export CARGO_TARGET_X86_64_LINUX_ANDROID_RUSTFLAGS="-L$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/lib/clang/17/lib/linux"

# For macOS hosts (adjust based on your system)
export CARGO_TARGET_X86_64_LINUX_ANDROID_RUSTFLAGS="-L$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/lib/clang/17/lib/linux"
```

### Required Tools
```bash
# Verify these are installed
rustc --version          # Rust 1.70+
cargo --version          # Cargo
node --version           # Node.js 18+
yarn --version           # Yarn 3+
ubrn --version           # uniffi-bindgen-react-native 0.29.3-1
```

### Android Targets
```bash
# Install required Rust targets
rustup target add aarch64-linux-android armv7-linux-androideabi
```

## 📦 Files Created by Successful Build

### Native Libraries
```
android/src/main/jniLibs/
├── arm64-v8a/
│   └── libmatrix_sdk_ffi.so (97MB)
└── armeabi-v7a/
    └── libmatrix_sdk_ffi.so (69MB)
```

### Generated Bindings
```
android/src/main/java/
├── com/unomed/reactnativematrixsdk/    # React Native module
├── org/matrix/rustcomponents/sdk/     # Main FFI bindings (1.9MB)
└── uniffi/                            # Individual crate bindings
    ├── matrix_sdk/
    ├── matrix_sdk_base/
    ├── matrix_sdk_common/
    ├── matrix_sdk_crypto/
    └── matrix_sdk_ui/

src/generated/
├── matrix_sdk_ffi.ts (1.4MB)         # Main TypeScript bindings
├── matrix_sdk_ffi-ffi.ts             # FFI layer
└── [other generated files]

cpp/generated/
├── matrix_sdk_ffi.cpp (1.9MB)        # C++ bindings
├── matrix_sdk_ffi.hpp
└── [other C++ files]
```

## 🔧 Why This Process Works

### 1. Correct Patch Application
- The `matrix-rust-sdk.patch` successfully applies without conflicts
- Contains complete VoIP fixes from morning's work
- Includes both client.rs modifications and voip.rs file

### 2. Proper Build Order
- Clean → Checkout → Build → Generate → Sort
- Each step depends on the previous completing successfully

### 3. Complete Native Libraries
- Builds for both ARM architectures (required for Android)
- Includes all FFI bindings and dependencies
- Proper uniffi initialization order

### 4. Working VoIP Implementation
- Event handlers properly stored (not dropped)
- Async/sync bridge using `tokio::spawn_blocking`
- Complete VoIP event types imported and available

## 🚀 Quick Reproduction Steps

To reproduce this exact build:

```bash
# 1. Ensure environment is set up
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125

# 2. Run the working build command
yarn generate:release:android

# 3. Package for distribution
npm pack
```

**Total build time:** ~4-6 minutes
**Final package size:** 166MB (includes native libraries)

## ✅ Verification of Success

### Build Success Indicators
1. ✅ No patch application errors
2. ✅ Rust compilation completes for both architectures
3. ✅ Native libraries created in jniLibs directories
4. ✅ TypeScript bindings generated successfully
5. ✅ Uniffi calls sorted properly
6. ✅ npm pack creates complete package

### VoIP Functionality Verification
```bash
# Check VoIP imports in built SDK
grep -n "OriginalSyncCallInviteEvent" rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs

# Check VoIP method in built SDK
grep -n "add_call_event_listener" rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs

# Check generated TypeScript bindings include VoIP
grep -n "CallEventListener" src/generated/matrix_sdk_ffi.ts
```

### Package Content Verification
```bash
# Check package includes native libraries
tar -tzf unomed-react-native-matrix-sdk-0.7.0.tgz | grep -E "\.so$|jniLibs"

# Check package size (should be ~166MB)
ls -lh unomed-react-native-matrix-sdk-0.7.0.tgz
```

## 🔄 Using the Package

### Installation
```bash
# In your app project
yarn add file:/path/to/unomed-react-native-matrix-sdk-0.7.0.tgz
```

### VoIP Usage
```typescript
import { Client, CallEventListener, CallType } from '@unomed/react-native-matrix-sdk';

// VoIP events will be properly received
const client = new Client(/* config */);

// Implement CallEventListener for handling incoming calls
class MyVoIPHandler implements CallEventListener {
  onInvite(roomId: string, callId: string, sender: string, offerSdp: string, callType: CallType) {
    console.log('📞 Incoming call received!');
  }
  // ... other event handlers
}

const voipHandler = new MyVoIPHandler();
await client.addCallEventListener(voipHandler);
```

## 🎉 Summary

**This build process successfully:**
- ✅ Applied all VoIP fixes from `matrix-rust-sdk.patch`
- ✅ Built complete native libraries for Android
- ✅ Generated all required FFI bindings
- ✅ Created working npm package with VoIP support
- ✅ Resolved previous TurboModule registration issues

**Key insight:** The `matrix-rust-sdk.patch` (160KB) IS the working patch containing all VoIP fixes. Previous build failures were due to file conflicts, not patch content issues.