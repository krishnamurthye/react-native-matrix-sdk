# VoIP and Normal Sync Usage Guide

This document explains how to use the VoIP and Normal Sync features that have been added to the react-native-matrix-sdk v0.7.0.

## Features Status

✅ **VoIP Support**: Fully implemented and exposed through the Client class
✅ **Normal Sync Support**: Fully implemented as an alternative to sliding sync

## VoIP Support Usage

### Setting up VoIP Event Listener

```typescript
import { Client, CallEventListener, IceCandidate, CallType } from '@unomed/react-native-matrix-sdk';

// Create a VoIP event listener
const voipListener: CallEventListener = {
  onInvite: async (roomId: string, callId: string, offer: string, callType: CallType) => {
    console.log('Incoming call:', { roomId, callId, callType });
    // Handle incoming call invitation
    // The 'offer' contains the SDP offer from the caller
  },

  onAnswer: async (roomId: string, callId: string, answer: string) => {
    console.log('Call answered:', { roomId, callId });
    // Handle call answer
    // The 'answer' contains the SDP answer from the callee
  },

  onCandidates: async (roomId: string, callId: string, candidates: IceCandidate[]) => {
    console.log('ICE candidates received:', { roomId, callId, candidates });
    // Handle ICE candidates for WebRTC connection
    // Each candidate has: candidate, sdpMid, sdpMLineIndex
  },

  onHangup: async (roomId: string, callId: string, reason: string) => {
    console.log('Call ended:', { roomId, callId, reason });
    // Handle call termination
  }
};

// Register the listener with the client
const client: Client = /* your authenticated client */;
const taskHandle = await client.addCallEventListener(voipListener);

// To stop listening for VoIP events
await taskHandle.cancel();
```

### Call Types

```typescript
enum CallType {
  Voice = "Voice",
  Video = "Video"
}
```

### ICE Candidate Structure

```typescript
interface IceCandidate {
  candidate: string;      // The ICE candidate string
  sdpMid: string;        // Media stream identification
  sdpMLineIndex: number; // Media line index
}
```

## Normal Sync Support Usage

Normal sync provides traditional Matrix v3 sync functionality as an alternative to sliding sync, useful for servers that don't support sliding sync.

### Getting the Normal Sync Manager

```typescript
import { Client, NormalSyncManager, NormalSyncConfig } from '@unomed/react-native-matrix-sdk';

const client: Client = /* your authenticated client */;

// Get the normal sync manager
const normalSyncManager: NormalSyncManager = client.normalSync();
```

### Performing a Single Sync

```typescript
// Sync once with default settings
const result = await normalSyncManager.syncOnce(
  30000,     // timeout in milliseconds (optional)
  undefined  // since token (optional, undefined for initial sync)
);

console.log('Sync result:', {
  nextBatch: result.nextBatch,  // Use this token for the next sync
  rooms: result.roomCount,
  events: result.eventCount
});
```

### Sync with Custom Configuration

```typescript
const syncConfig: NormalSyncConfig = {
  timeout: 30000,           // Timeout in milliseconds
  setPresence: true,        // Update user presence
  fullState: false,         // Request full state (initial sync)
  since: result.nextBatch   // Token from previous sync
};

const result = await normalSyncManager.syncWithConfig(syncConfig);
```

### Starting a Continuous Sync Loop

```typescript
// Start continuous sync (this is a helper method)
await normalSyncManager.startSyncLoop(
  30000,  // timeout per sync request
  false   // fullState (true for initial sync)
);

// Note: The actual loop implementation should be handled in TypeScript
// to allow for proper error handling and cancellation
```

### Implementing a Sync Loop in TypeScript

```typescript
async function runSyncLoop(client: Client) {
  const syncManager = client.normalSync();
  let nextBatch: string | undefined = undefined;
  let running = true;

  while (running) {
    try {
      const result = await syncManager.syncOnce(30000, nextBatch);
      nextBatch = result.nextBatch;

      // Process sync results
      console.log(`Synced: ${result.roomCount} rooms, ${result.eventCount} events`);

      // Small delay between syncs
      await new Promise(resolve => setTimeout(resolve, 100));
    } catch (error) {
      console.error('Sync error:', error);
      // Handle error - maybe wait before retrying
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
}
```

## Complete Example

```typescript
import {
  Client,
  CallEventListener,
  NormalSyncManager,
  CallType
} from '@unomed/react-native-matrix-sdk';

async function setupMatrixClient(client: Client) {
  // 1. Set up VoIP listener
  const voipListener: CallEventListener = {
    onInvite: async (roomId, callId, offer, callType) => {
      if (callType === CallType.Video) {
        // Handle video call
        console.log('Incoming video call in room:', roomId);
      } else {
        // Handle voice call
        console.log('Incoming voice call in room:', roomId);
      }
    },
    onAnswer: async (roomId, callId, answer) => {
      console.log('Call answered in room:', roomId);
    },
    onCandidates: async (roomId, callId, candidates) => {
      console.log(`Received ${candidates.length} ICE candidates`);
    },
    onHangup: async (roomId, callId, reason) => {
      console.log('Call ended:', reason);
    }
  };

  const voipHandle = await client.addCallEventListener(voipListener);

  // 2. Start normal sync
  const syncManager = client.normalSync();

  // Initial sync
  const initialSync = await syncManager.syncOnce(30000, undefined);
  console.log('Initial sync completed, next batch:', initialSync.nextBatch);

  // Continue syncing
  let nextBatch = initialSync.nextBatch;
  setInterval(async () => {
    try {
      const result = await syncManager.syncOnce(30000, nextBatch);
      nextBatch = result.nextBatch;
      console.log('Sync update received');
    } catch (error) {
      console.error('Sync failed:', error);
    }
  }, 30000);
}
```

## Installation

To use these features, install the package:

```bash
yarn add file:/path/to/unomed-react-native-matrix-sdk-0.7.0.tgz
```

## Requirements

- React Native 0.70+
- Android SDK 21+
- iOS 13+
- Matrix server with VoIP support (for VoIP features)
- Any Matrix server (for normal sync)

## Notes

1. **VoIP**: The VoIP implementation provides the signaling layer for WebRTC calls. You'll need to integrate with a WebRTC library (like react-native-webrtc) to handle the actual media streams.

2. **Normal Sync**: This is useful when:
   - Your server doesn't support sliding sync
   - You need compatibility with older Matrix servers
   - You want to use the traditional sync approach

3. Both features work independently - you can use VoIP with sliding sync or normal sync, depending on your needs.