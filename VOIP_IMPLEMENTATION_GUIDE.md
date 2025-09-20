# VoIP Implementation Guide for React Native Matrix SDK

## ✅ Current Status

The VoIP support is **fully implemented** in the FFI layer. All required types and methods are available in the generated TypeScript bindings.

## Available VoIP APIs

### 1. Core Types

```typescript
// Call event listener interface
interface CallEventListener {
  onInvite(roomId: string, callId: string, sender: string, offerSdp: string, callType: CallType, version: number): void;
  onAnswer(roomId: string, callId: string, sender: string, answerSdp: string): void;
  onCandidates(roomId: string, callId: string, sender: string, candidates: Array<IceCandidate>): void;
  onHangup(roomId: string, callId: string, sender: string, reason?: string): void;
  onNegotiate(roomId: string, callId: string, sender: string, offerSdp: string): void;
  onSelectAnswer(roomId: string, callId: string, sender: string, selectedPartyId: string): void;
  onReject(roomId: string, callId: string, sender: string, reason?: string): void;
}

// Call types
enum CallType {
  Voice = "Voice",
  Video = "Video"
}

// ICE candidate for WebRTC
type IceCandidate = {
  candidate: string;
  sdpMid: string | null;
  sdpMLineIndex: number | null;
}

// Outgoing call structures
type OutgoingCallInvite = {
  callId: string;
  partyId: string;
  offerSdp: string;
  callType: CallType;
  version: number;
}

type OutgoingCallAnswer = {
  callId: string;
  partyId: string;
  answerSdp: string;
  version: number;
}

type OutgoingCallCandidates = {
  callId: string;
  partyId: string;
  candidates: Array<IceCandidate>;
  version: number;
}

type OutgoingCallHangup = {
  callId: string;
  partyId: string;
  reason: string | null;
  version: number;
}
```

### 2. Client Methods

```typescript
class Client {
  // Register a call event listener
  async addCallEventListener(listener: CallEventListener): Promise<CallEventListenerHandle>;

  // Send call events to a room
  async sendCallInvite(roomId: string, invite: OutgoingCallInvite): Promise<void>;
  async sendCallAnswer(roomId: string, answer: OutgoingCallAnswer): Promise<void>;
  async sendCallCandidates(roomId: string, candidates: OutgoingCallCandidates): Promise<void>;
  async sendCallHangup(roomId: string, hangup: OutgoingCallHangup): Promise<void>;
}
```

## Implementation Example

### Basic VoIP Handler

```typescript
import {
  Client,
  CallEventListener,
  CallType,
  IceCandidate,
  OutgoingCallInvite,
  OutgoingCallAnswer,
  OutgoingCallCandidates,
  OutgoingCallHangup
} from '@unomed/react-native-matrix-sdk';

class VoIPHandler implements CallEventListener {
  private client: Client;
  private peerConnection: RTCPeerConnection | null = null;
  private localStream: MediaStream | null = null;
  private callId: string | null = null;
  private roomId: string | null = null;

  constructor(client: Client) {
    this.client = client;
  }

  async initialize() {
    // Register this handler to receive call events
    await this.client.addCallEventListener(this);
  }

  // Incoming call handlers
  onInvite(
    roomId: string,
    callId: string,
    sender: string,
    offerSdp: string,
    callType: CallType,
    version: number
  ) {
    console.log(`Incoming ${callType} call from ${sender} in room ${roomId}`);
    this.callId = callId;
    this.roomId = roomId;

    // Set up WebRTC peer connection
    this.setupPeerConnection();

    // Set remote description
    this.peerConnection?.setRemoteDescription({
      type: 'offer',
      sdp: offerSdp
    });

    // Handle the call (show UI, etc.)
    this.handleIncomingCall(sender, callType);
  }

  onAnswer(
    roomId: string,
    callId: string,
    sender: string,
    answerSdp: string
  ) {
    console.log(`Call answered by ${sender}`);

    // Set remote answer
    this.peerConnection?.setRemoteDescription({
      type: 'answer',
      sdp: answerSdp
    });
  }

  onCandidates(
    roomId: string,
    callId: string,
    sender: string,
    candidates: Array<IceCandidate>
  ) {
    console.log(`Received ${candidates.length} ICE candidates`);

    // Add ICE candidates to peer connection
    candidates.forEach(candidate => {
      this.peerConnection?.addIceCandidate({
        candidate: candidate.candidate,
        sdpMid: candidate.sdpMid || undefined,
        sdpMLineIndex: candidate.sdpMLineIndex || undefined
      });
    });
  }

  onHangup(
    roomId: string,
    callId: string,
    sender: string,
    reason?: string
  ) {
    console.log(`Call ended by ${sender}. Reason: ${reason || 'none'}`);
    this.endCall();
  }

  onNegotiate(
    roomId: string,
    callId: string,
    sender: string,
    offerSdp: string
  ) {
    console.log('Call renegotiation requested');
    // Handle renegotiation for network changes
  }

  onSelectAnswer(
    roomId: string,
    callId: string,
    sender: string,
    selectedPartyId: string
  ) {
    console.log(`Answer selected for party: ${selectedPartyId}`);
    // Handle multi-device scenarios
  }

  onReject(
    roomId: string,
    callId: string,
    sender: string,
    reason?: string
  ) {
    console.log(`Call rejected by ${sender}. Reason: ${reason || 'none'}`);
    this.endCall();
  }

  // Outgoing call methods
  async startCall(roomId: string, isVideo: boolean) {
    this.roomId = roomId;
    this.callId = generateCallId(); // Your ID generation logic

    // Set up peer connection
    this.setupPeerConnection();

    // Get user media
    this.localStream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: isVideo
    });

    // Add tracks to peer connection
    this.localStream.getTracks().forEach(track => {
      this.peerConnection?.addTrack(track, this.localStream!);
    });

    // Create offer
    const offer = await this.peerConnection!.createOffer();
    await this.peerConnection!.setLocalDescription(offer);

    // Send invite through Matrix
    const invite: OutgoingCallInvite = {
      callId: this.callId,
      partyId: generatePartyId(), // Your party ID logic
      offerSdp: offer.sdp!,
      callType: isVideo ? CallType.Video : CallType.Voice,
      version: 1
    };

    await this.client.sendCallInvite(roomId, invite);
  }

  async answerCall() {
    if (!this.peerConnection || !this.callId || !this.roomId) return;

    // Get user media
    this.localStream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: false // or true for video
    });

    // Add tracks
    this.localStream.getTracks().forEach(track => {
      this.peerConnection?.addTrack(track, this.localStream!);
    });

    // Create answer
    const answer = await this.peerConnection.createAnswer();
    await this.peerConnection.setLocalDescription(answer);

    // Send answer through Matrix
    const callAnswer: OutgoingCallAnswer = {
      callId: this.callId,
      partyId: generatePartyId(),
      answerSdp: answer.sdp!,
      version: 1
    };

    await this.client.sendCallAnswer(this.roomId, callAnswer);
  }

  async hangup() {
    if (!this.callId || !this.roomId) return;

    const hangup: OutgoingCallHangup = {
      callId: this.callId,
      partyId: generatePartyId(),
      reason: 'user_hangup',
      version: 1
    };

    await this.client.sendCallHangup(this.roomId, hangup);
    this.endCall();
  }

  private setupPeerConnection() {
    this.peerConnection = new RTCPeerConnection({
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' }
        // Add your TURN servers here
      ]
    });

    // Handle ICE candidates
    this.peerConnection.onicecandidate = async (event) => {
      if (event.candidate && this.callId && this.roomId) {
        const candidates: OutgoingCallCandidates = {
          callId: this.callId,
          partyId: generatePartyId(),
          candidates: [{
            candidate: event.candidate.candidate,
            sdpMid: event.candidate.sdpMid,
            sdpMLineIndex: event.candidate.sdpMLineIndex
          }],
          version: 1
        };

        await this.client.sendCallCandidates(this.roomId, candidates);
      }
    };

    // Handle remote stream
    this.peerConnection.ontrack = (event) => {
      console.log('Remote stream received', event.streams[0]);
      // Handle remote stream (update UI, etc.)
    };
  }

  private handleIncomingCall(sender: string, callType: CallType) {
    // Show incoming call UI
    // Let user accept or reject
  }

  private endCall() {
    // Clean up resources
    this.localStream?.getTracks().forEach(track => track.stop());
    this.peerConnection?.close();
    this.peerConnection = null;
    this.localStream = null;
    this.callId = null;
    this.roomId = null;
  }
}

// Usage
async function initializeVoIP(client: Client) {
  const voipHandler = new VoIPHandler(client);
  await voipHandler.initialize();

  // Now the handler will receive all call events
  // You can also initiate calls:
  // await voipHandler.startCall(roomId, false); // Voice call
  // await voipHandler.startCall(roomId, true);  // Video call
}
```

## Integration Steps

1. **Import the types**:
```typescript
import {
  Client,
  CallEventListener,
  CallType,
  IceCandidate
} from '@unomed/react-native-matrix-sdk';
```

2. **Implement CallEventListener**:
Create a class that implements all the callback methods

3. **Register the listener**:
```typescript
const handle = await client.addCallEventListener(myListener);
```

4. **Send call events**:
Use the client's sendCall* methods to initiate and manage calls

## Key Points

- ✅ All VoIP FFI bindings are already generated
- ✅ The `Client` class has `addCallEventListener` method
- ✅ All call event types are properly typed
- ✅ Both incoming and outgoing call flows are supported
- ✅ ICE candidate exchange is supported
- ✅ Multi-device scenarios handled (select_answer)

## Testing

To test VoIP functionality:

1. Create two client instances (different users)
2. Register call event listeners on both
3. Initiate a call from one client
4. Observe events on the receiving client
5. Answer the call and exchange ICE candidates
6. Verify audio/video streams are established
7. Test hangup from either side

## Notes

- The FFI layer handles the Matrix protocol details
- You need to implement WebRTC handling separately
- Use proper STUN/TURN servers for NAT traversal
- Handle permissions for microphone/camera access
- Implement proper error handling and reconnection logic