# VoIP Usage Summary - React Native Matrix SDK

## Quick Start

```typescript
import { Client, CallEventListener, CallType } from '@unomed/react-native-matrix-sdk';

// 1. Create VoIP listener
const voipListener: CallEventListener = {
  onInvite: async (roomId, callId, offer, callType) => {
    console.log(`Incoming ${callType} call in room ${roomId}`);
    // Handle incoming call
  },
  onAnswer: async (roomId, callId, answer) => {
    console.log(`Call ${callId} answered`);
    // Handle answer
  },
  onCandidates: async (roomId, callId, candidates) => {
    console.log(`Received ${candidates.length} ICE candidates`);
    // Handle ICE candidates
  },
  onHangup: async (roomId, callId, reason) => {
    console.log(`Call ${callId} ended: ${reason}`);
    // Handle hangup
  }
};

// 2. Register listener with client
const client: Client = /* your authenticated client */;
const taskHandle = await client.addCallEventListener(voipListener);

// 3. To stop listening
await taskHandle.cancel();
```

## Event Details

### onInvite
- **Triggered**: When receiving a call invitation
- **Parameters**:
  - `roomId`: Matrix room ID
  - `callId`: Unique call identifier
  - `offer`: SDP offer string for WebRTC
  - `callType`: `CallType.Voice` or `CallType.Video`

### onAnswer
- **Triggered**: When call is answered
- **Parameters**:
  - `roomId`: Matrix room ID
  - `callId`: Unique call identifier
  - `answer`: SDP answer string for WebRTC

### onCandidates
- **Triggered**: When ICE candidates are received
- **Parameters**:
  - `roomId`: Matrix room ID
  - `callId`: Unique call identifier
  - `candidates`: Array of `IceCandidate` objects
    ```typescript
    {
      candidate: string,     // ICE candidate string
      sdpMid: string,       // Media stream ID
      sdpMLineIndex: number // Media line index
    }
    ```

### onHangup
- **Triggered**: When call ends
- **Parameters**:
  - `roomId`: Matrix room ID
  - `callId`: Unique call identifier
  - `reason`: String describing hangup reason

## Complete Implementation Example

```typescript
import {
  Client,
  CallEventListener,
  CallType,
  IceCandidate
} from '@unomed/react-native-matrix-sdk';
import RTCPeerConnection from 'react-native-webrtc'; // WebRTC integration

class VoIPManager {
  private client: Client;
  private peerConnections: Map<string, RTCPeerConnection> = new Map();
  private taskHandle?: any;

  constructor(client: Client) {
    this.client = client;
  }

  async initialize() {
    const listener: CallEventListener = {
      onInvite: this.handleInvite.bind(this),
      onAnswer: this.handleAnswer.bind(this),
      onCandidates: this.handleCandidates.bind(this),
      onHangup: this.handleHangup.bind(this)
    };

    this.taskHandle = await this.client.addCallEventListener(listener);
  }

  private async handleInvite(
    roomId: string,
    callId: string,
    offer: string,
    callType: CallType
  ) {
    console.log(`📞 Incoming ${callType} call`);

    // Create peer connection
    const pc = new RTCPeerConnection(/* config */);
    this.peerConnections.set(callId, pc);

    // Set remote description
    await pc.setRemoteDescription({ type: 'offer', sdp: offer });

    // Create answer
    const answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    // Send answer back through Matrix (implementation depends on your setup)
    // await this.sendAnswer(roomId, callId, answer.sdp);

    // Show UI for incoming call
    this.showIncomingCallUI(roomId, callType);
  }

  private async handleAnswer(
    roomId: string,
    callId: string,
    answer: string
  ) {
    const pc = this.peerConnections.get(callId);
    if (pc) {
      await pc.setRemoteDescription({ type: 'answer', sdp: answer });
      console.log('✅ Call connected');
    }
  }

  private async handleCandidates(
    roomId: string,
    callId: string,
    candidates: IceCandidate[]
  ) {
    const pc = this.peerConnections.get(callId);
    if (pc) {
      for (const candidate of candidates) {
        await pc.addIceCandidate({
          candidate: candidate.candidate,
          sdpMid: candidate.sdpMid,
          sdpMLineIndex: candidate.sdpMLineIndex
        });
      }
      console.log(`🧊 Added ${candidates.length} ICE candidates`);
    }
  }

  private async handleHangup(
    roomId: string,
    callId: string,
    reason: string
  ) {
    const pc = this.peerConnections.get(callId);
    if (pc) {
      pc.close();
      this.peerConnections.delete(callId);
    }
    console.log(`📴 Call ended: ${reason}`);
    this.hideCallUI();
  }

  private showIncomingCallUI(roomId: string, callType: CallType) {
    // Show your call UI
  }

  private hideCallUI() {
    // Hide your call UI
  }

  async cleanup() {
    if (this.taskHandle) {
      await this.taskHandle.cancel();
    }

    // Close all peer connections
    for (const pc of this.peerConnections.values()) {
      pc.close();
    }
    this.peerConnections.clear();
  }
}

// Usage
const client = /* your Matrix client */;
const voipManager = new VoIPManager(client);
await voipManager.initialize();
```

## Integration with WebRTC

The VoIP events provide the signaling layer. You need to:

1. **Install WebRTC library**:
   ```bash
   yarn add react-native-webrtc
   ```

2. **Handle SDP exchange**:
   - Receive SDP offer in `onInvite`
   - Send SDP answer through Matrix
   - Receive SDP answer in `onAnswer`

3. **Handle ICE candidates**:
   - Receive candidates in `onCandidates`
   - Send your candidates through Matrix

4. **Manage peer connections**:
   - Create RTCPeerConnection for each call
   - Add media streams (audio/video)
   - Clean up on hangup

## Testing VoIP

```typescript
// Simple test to verify VoIP events are working
const testVoIP = async (client: Client) => {
  const listener: CallEventListener = {
    onInvite: async (roomId, callId, offer, callType) => {
      console.log('✅ VoIP Working: Received invite');
      console.log('Room:', roomId);
      console.log('Call Type:', callType);
      console.log('SDP Offer length:', offer.length);
    },
    onAnswer: async () => console.log('✅ Answer received'),
    onCandidates: async (_, __, candidates) => {
      console.log('✅ ICE candidates:', candidates.length);
    },
    onHangup: async (_, __, reason) => {
      console.log('✅ Hangup:', reason);
    }
  };

  const handle = await client.addCallEventListener(listener);
  console.log('VoIP listener registered. Waiting for calls...');

  // Clean up after testing
  setTimeout(async () => {
    await handle.cancel();
    console.log('VoIP listener cancelled');
  }, 60000); // Stop after 1 minute
};
```

## Key Points

1. **Signaling Only**: This provides Matrix signaling, not media handling
2. **WebRTC Required**: Integrate with react-native-webrtc for actual calls
3. **Room-Based**: All calls are associated with Matrix rooms
4. **Call Types**: Supports both Voice and Video calls
5. **ICE Support**: Full ICE candidate exchange for NAT traversal

## Troubleshooting

- **No events received**: Ensure client is syncing (use `client.startSync()` or `client.normalSync()`)
- **Call not connecting**: Check ICE candidates are being exchanged properly
- **Audio/Video issues**: These are WebRTC issues, not Matrix signaling issues

## Package Installation

```bash
# Install the package with VoIP support
yarn add file:/home/lalitha/workspace_rust/react-native-matrix-sdk/unomed-react-native-matrix-sdk-0.7.0.tgz
```

## Version Info

- **Package**: @unomed/react-native-matrix-sdk
- **Version**: 0.7.0
- **VoIP Added**: Through `addCallEventListener` method on Client
- **Native Libraries**: Include VoIP-enabled libmatrix_sdk_ffi.so