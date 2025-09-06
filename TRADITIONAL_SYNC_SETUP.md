# Traditional Sync Setup Guide for React Native Matrix SDK

## Overview

This guide provides complete instructions for using traditional Matrix sync (v3) in your React Native Matrix SDK when your server doesn't support or has issues with sliding sync.

## Current Status ✅

All traditional sync support code is in place:

1. ✅ `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/lib.rs` - Module included
2. ✅ `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/normal_sync.rs` - Implementation ready
3. ✅ `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs` - Client method added

## Building the SDK

### Quick Build

```bash
cd /home/lalitha/workspace_rust/react-native-matrix-sdk
./build_traditional_sync.sh
```

### Manual Build Steps

```bash
# 1. Navigate to the project
cd /home/lalitha/workspace_rust/react-native-matrix-sdk

# 2. Build the Rust FFI library
cd rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi
cargo build --release

# 3. Return to project root
cd /home/lalitha/workspace_rust/react-native-matrix-sdk

# 4. Generate TypeScript bindings
yarn generate

# 5. Build the complete package
yarn build
```

## Using Traditional Sync in Your App

### Method 1: Direct Traditional Sync

```typescript
import { 
  ClientBuilder, 
  SlidingSyncVersionBuilder,
  NormalSyncConfig,
  NormalSyncResult 
} from '@unomed/react-native-matrix-sdk';

// Step 1: Build client WITHOUT sliding sync
const client = await new ClientBuilder()
  .homeserverUrl('http://localhost:8008')
  .slidingSyncVersionBuilder(SlidingSyncVersionBuilder.None) // IMPORTANT: Disable sliding sync
  .build();

// Step 2: Login
await client.login('username', 'password');

// Step 3: Get the normal sync manager
const normalSync = client.normalSync();

// Step 4: Perform sync
// Simple sync
const nextBatch = await normalSync.syncOnce(
  30000,  // timeout in ms (optional)
  null    // previous sync token (null for first sync)
);

// Or sync with full configuration
const config: NormalSyncConfig = {
  timeout_ms: 30000,
  full_state: false,  // true for first sync to get all room state
  set_presence: "online"
};

const result: NormalSyncResult = await normalSync.syncWithConfig(config);
console.log('Sync result:', {
  next_batch: result.next_batch,
  rooms_updated: result.rooms_updated,
  has_presence_updates: result.has_presence_updates,
  has_to_device_messages: result.has_to_device_messages
});
```

### Method 2: Continuous Sync Loop

```typescript
class TraditionalSyncManager {
  private client: Client;
  private syncToken: string | null = null;
  private isRunning = false;

  constructor(client: Client) {
    this.client = client;
  }

  async startSync() {
    if (this.isRunning) return;
    
    this.isRunning = true;
    const normalSync = this.client.normalSync();
    let retryDelay = 1000;
    
    while (this.isRunning) {
      try {
        // Perform sync with long-polling
        const config: NormalSyncConfig = {
          timeout_ms: 30000,  // 30 second long-poll
          full_state: this.syncToken === null,  // Full state on first sync only
          set_presence: "online"
        };
        
        const result = await normalSync.syncWithConfig(config);
        this.syncToken = result.next_batch;
        
        // Process sync results
        console.log(`Synced: ${result.rooms_updated} rooms updated`);
        
        // Reset retry delay on success
        retryDelay = 1000;
        
        // Process rooms
        await this.processRooms();
        
      } catch (error) {
        console.error('Sync error:', error);
        
        // Exponential backoff
        await this.delay(retryDelay);
        retryDelay = Math.min(retryDelay * 2, 30000);
      }
    }
  }

  stopSync() {
    this.isRunning = false;
  }

  private async processRooms() {
    const rooms = await this.client.rooms();
    for (const room of rooms) {
      // Process each room
      const roomId = room.id();
      const displayName = room.displayName();
      // Handle messages, events, etc.
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Usage
const syncManager = new TraditionalSyncManager(client);
await syncManager.startSync();
```

### Method 3: Use the Universal Sync Client

For automatic fallback between sliding sync and traditional sync, use the `UniversalSyncClient` from `example/src/UniversalSyncClient.ts`:

```typescript
import { UniversalSyncClient } from './UniversalSyncClient';

const universalClient = new UniversalSyncClient({
  homeserverUrl: 'http://localhost:8008',
  username: 'user',
  password: 'password',
  onSyncUpdate: (token) => console.log('Sync token:', token),
  onError: (error) => console.error('Error:', error),
  onRoomsUpdate: (count) => console.log(`${count} rooms updated`)
});

await universalClient.initialize();  // Auto-detects best sync method
await universalClient.startSync();   // Starts appropriate sync
```

## Types Reference

### NormalSyncConfig
```typescript
interface NormalSyncConfig {
  timeout_ms: number;           // Timeout in milliseconds for long polling
  full_state: boolean;          // Whether to request full state
  set_presence?: string | null; // Presence state: "online", "offline", "unavailable"
}
```

### NormalSyncResult
```typescript
interface NormalSyncResult {
  next_batch: string;              // Token for next sync
  rooms_updated: number;           // Number of rooms with updates
  has_presence_updates: boolean;   // Whether there were presence updates
  has_to_device_messages: boolean; // Whether there were to-device messages
}
```

## Common Issues and Solutions

### Issue: "Sliding sync version is missing"
**Solution**: Ensure you're using `SlidingSyncVersionBuilder.None` when building the client.

### Issue: "Sync failed: Network timeout"
**Solution**: 
- Increase the timeout value (e.g., 60000 for 60 seconds)
- Check network connectivity
- Verify the homeserver URL is correct

### Issue: Missing room data
**Solution**: Set `full_state: true` for the first sync to get complete room state.

### Issue: High bandwidth usage
**Solution**: Traditional sync is more bandwidth-intensive than sliding sync. Consider:
- Implementing local caching
- Using filters to reduce data
- Batching UI updates

## Performance Considerations

1. **Battery Life**: Long-polling keeps connections open. Implement proper lifecycle management.
2. **Network Usage**: Each sync contains all changes since last sync. Can be data-intensive.
3. **Memory**: Store sync tokens persistently to resume after app restart.
4. **Error Handling**: Implement exponential backoff for network errors.

## Server Compatibility

Traditional sync (v3) works with ALL Matrix homeservers:
- ✅ Synapse (all versions)
- ✅ Dendrite
- ✅ Conduit
- ✅ Any Matrix-compliant server

No special server configuration required!

## Testing

Test your implementation:

```typescript
// Test function
async function testTraditionalSync() {
  try {
    const client = await new ClientBuilder()
      .homeserverUrl('http://localhost:8008')
      .slidingSyncVersionBuilder(SlidingSyncVersionBuilder.None)
      .build();
    
    await client.login('test_user', 'test_password');
    
    const normalSync = client.normalSync();
    const token = await normalSync.syncOnce(5000, null);
    
    console.log('✅ Traditional sync working! Token:', token);
    return true;
  } catch (error) {
    console.error('❌ Traditional sync failed:', error);
    return false;
  }
}

testTraditionalSync();
```

## Complete Working Examples

1. **`example/src/TraditionalSyncExample.tsx`** - Full React Native component with UI
2. **`example/src/UniversalSyncClient.ts`** - Smart client with automatic fallback
3. **`example/src/UniversalSyncExample.tsx`** - Complete UI example with both sync methods

## Summary

Traditional sync is now fully supported in your React Native Matrix SDK. It provides a reliable fallback when sliding sync is unavailable or problematic. Simply disable sliding sync in the ClientBuilder and use the `normalSync()` method to access traditional sync functionality.