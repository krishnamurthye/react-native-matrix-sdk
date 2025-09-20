# VoIP Fix for React Native Matrix SDK

This package contains fixes for incoming call issues in the Matrix SDK.

## What was fixed

The original issue was that incoming VoIP calls were not being received properly. This was caused by:

1. **Event handler lifetime issue** - Event handlers were being immediately dropped
2. **Async/sync callback mismatch** - Synchronous callbacks were called from async context incorrectly
3. **Missing event handler storage** - No proper mechanism to keep handlers alive

## Fix details

The following changes were made to `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs`:

1. Added `add_call_event_listener` method that properly stores event handler references
2. Fixed async/sync callback handling using `tokio::task::spawn_blocking`
3. Added proper import statements for call events
4. Modified the download script to skip binary download when local binaries exist

## Installation

### Option 1: Install from local package (Recommended)

```bash
# Install the fixed package directly
yarn add file:/path/to/unomed-react-native-matrix-sdk-0.7.0.tgz

# Or using npm
npm install /path/to/unomed-react-native-matrix-sdk-0.7.0.tgz
```

### Option 2: Build from source

```bash
# Clone this repository
git clone <repository-url>
cd react-native-matrix-sdk

# Build the package
yarn generate:release:android
yarn generate:release:ios  # If you need iOS support

# Pack the package
npm pack

# Install in your project
yarn add file:./unomed-react-native-matrix-sdk-0.7.0.tgz
```

## Usage

After installation, incoming calls should work automatically. The VoIP event listeners are registered when you initialize the Matrix client.

```typescript
import { Client } from '@unomed/react-native-matrix-sdk';

// Initialize client as usual
const client = new Client(/* your config */);

// VoIP events will now be properly received
```

## Package size note

The package includes native Android libraries (~305MB) which results in a large APK size (~460MB). For production apps, consider:

1. Using Android App Bundle (AAB) format for Google Play Store
2. Implementing ABI splits to create separate APKs per architecture
3. Enabling ProGuard/R8 minification

## Build configuration for large packages

Add to your `android/gradle.properties`:

```properties
# Increase JVM memory for large packages
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError

# Enable proper packaging
android.packagingOptions.jniLibs.useLegacyPackaging=false
android.enableJetifier=true
```

## Verification

To verify the fix is working:

1. Install the package in your app
2. Rebuild and install your app
3. Test incoming VoIP calls
4. Check that `TurboModuleRegistry.getEnforcing(...): 'ReactNativeMatrixSdk'` errors are resolved
5. Verify that call events are being received properly

## Troubleshooting

### Module not found error

If you get `'ReactNativeMatrixSdk' could not be found` error:

1. Ensure you've installed the package correctly
2. Clean and rebuild your project:
   ```bash
   cd android && ./gradlew clean && cd ..
   npx react-native run-android
   ```

### Build failures

If Android build fails with packaging errors:

1. Increase gradle memory settings (see above)
2. Use direct gradle build instead of Expo CLI:
   ```bash
   cd android && ./gradlew app:assembleDebug
   ```

### Large APK size

The APK will be ~460MB due to native libraries. This is expected for Matrix SDK with VoIP support.

## Technical details

The fix involves:

1. **Event Handler Storage**: Instead of dropping event handlers immediately, they're stored in a tuple and kept alive via `Arc<TaskHandle>`
2. **Async/Sync Bridge**: Using `tokio::task::spawn_blocking` to properly call synchronous VoIP callbacks from async event handlers
3. **Proper Imports**: Added necessary imports for call events (`OriginalSyncCallInviteEvent`, etc.)
4. **Binary Detection**: Modified download script to detect existing native binaries

## Files modified

- `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs` - Added VoIP event listener
- `scripts/download-binaries.js` - Skip download when binaries exist locally
- Various generated binding files updated with new VoIP APIs

This ensures that incoming VoIP calls are properly received and handled by your React Native application.