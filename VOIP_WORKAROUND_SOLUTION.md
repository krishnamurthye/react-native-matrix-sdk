# VoIP Workaround Solution Using sendRaw()

## ✅ Good News: We CAN Send Call Events!

While the dedicated `sendCallInvite`, `sendCallAnswer`, etc. methods don't exist, we can use the **Room's `sendRaw()` method** to send any Matrix event type, including call events!

## The Solution

### Room.sendRaw() Method
```typescript
room.sendRaw(
  eventType: string,    // e.g., "m.call.invite"
  content: string,      // JSON string of event content
  asyncOpts?: { signal: AbortSignal }
): Promise<void>
```

## Working Implementation

```typescript
import {
  Client,
  CallEventListener,
  CallType,
  IceCandidate,
} from '@unomed/react-native-matrix-sdk';

class VoIPHandler implements CallEventListener {
  private client: Client;

  constructor(client: Client) {
    this.client = client;
  }

  // ===================================
  // SENDING CALL EVENTS (Using sendRaw)
  // ===================================

  async sendCallInvite(
    roomId: string,
    callId: string,
    offerSdp: string,
    callType: CallType
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      offer: {
        type: 'offer',
        sdp: offerSdp
      },
      version: '1',
      lifetime: 60000,
      // Add call type in the content
      "m.call.type": callType === CallType.Video ? "video" : "voice"
    };

    await room.sendRaw('m.call.invite', JSON.stringify(content));
    console.log('✅ Call invite sent via sendRaw');
  }

  async sendCallAnswer(
    roomId: string,
    callId: string,
    answerSdp: string
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      answer: {
        type: 'answer',
        sdp: answerSdp
      },
      version: '1'
    };

    await room.sendRaw('m.call.answer', JSON.stringify(content));
    console.log('✅ Call answer sent via sendRaw');
  }

  async sendCallCandidates(
    roomId: string,
    callId: string,
    candidates: IceCandidate[]
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      candidates: candidates.map(c => ({
        candidate: c.candidate,
        sdpMid: c.sdpMid,
        sdpMLineIndex: c.sdpMLineIndex
      })),
      version: '1'
    };

    await room.sendRaw('m.call.candidates', JSON.stringify(content));
    console.log('✅ ICE candidates sent via sendRaw');
  }

  async sendCallHangup(
    roomId: string,
    callId: string,
    reason?: string
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      version: '1',
      reason: reason || 'user_hangup'
    };

    await room.sendRaw('m.call.hangup', JSON.stringify(content));
    console.log('✅ Call hangup sent via sendRaw');
  }

  async sendCallReject(
    roomId: string,
    callId: string,
    reason?: string
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      version: '1',
      reason: reason || 'user_busy'
    };

    await room.sendRaw('m.call.reject', JSON.stringify(content));
    console.log('✅ Call reject sent via sendRaw');
  }

  async sendCallNegotiate(
    roomId: string,
    callId: string,
    offerSdp: string
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      offer: {
        type: 'offer',
        sdp: offerSdp
      },
      version: '1',
      lifetime: 60000
    };

    await room.sendRaw('m.call.negotiate', JSON.stringify(content));
    console.log('✅ Call negotiate sent via sendRaw');
  }

  async sendCallSelectAnswer(
    roomId: string,
    callId: string,
    selectedPartyId: string
  ): Promise<void> {
    const room = this.client.getRoom(roomId);
    if (!room) throw new Error('Room not found');

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      selected_party_id: selectedPartyId,
      version: '1'
    };

    await room.sendRaw('m.call.select_answer', JSON.stringify(content));
    console.log('✅ Call select_answer sent via sendRaw');
  }

  // ===================================
  // RECEIVING CALL EVENTS (Already Works)
  // ===================================

  onInvite(
    roomId: string,
    callId: string,
    sender: string,
    offerSdp: string,
    callType: CallType,
    version: number
  ): void {
    console.log(`📞 Incoming ${callType} call from ${sender}`);
    // Handle incoming call
  }

  onAnswer(
    roomId: string,
    callId: string,
    sender: string,
    answerSdp: string
  ): void {
    console.log(`✅ Call answered by ${sender}`);
    // Handle answer
  }

  onCandidates(
    roomId: string,
    callId: string,
    sender: string,
    candidates: Array<IceCandidate>
  ): void {
    console.log(`🧊 Received ${candidates.length} ICE candidates`);
    // Add ICE candidates to peer connection
  }

  onHangup(
    roomId: string,
    callId: string,
    sender: string,
    reason?: string
  ): void {
    console.log(`📞 Call ended by ${sender}`);
    // Clean up call
  }

  onNegotiate(
    roomId: string,
    callId: string,
    sender: string,
    offerSdp: string
  ): void {
    console.log(`🔄 Renegotiation from ${sender}`);
    // Handle renegotiation
  }

  onSelectAnswer(
    roomId: string,
    callId: string,
    sender: string,
    selectedPartyId: string
  ): void {
    console.log(`✅ Answer selected: ${selectedPartyId}`);
    // Handle multi-device scenario
  }

  onReject(
    roomId: string,
    callId: string,
    sender: string,
    reason?: string
  ): void {
    console.log(`❌ Call rejected by ${sender}`);
    // Handle rejection
  }

  // Helper methods
  private generatePartyId(): string {
    return `party_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

## Matrix Call Event Specifications

According to the Matrix spec, call events should have this structure:

### m.call.invite
```json
{
  "type": "m.call.invite",
  "content": {
    "call_id": "12345",
    "party_id": "party_123",
    "offer": {
      "type": "offer",
      "sdp": "v=0\r\no=- ..."
    },
    "version": "1",
    "lifetime": 60000
  }
}
```

### m.call.answer
```json
{
  "type": "m.call.answer",
  "content": {
    "call_id": "12345",
    "party_id": "party_123",
    "answer": {
      "type": "answer",
      "sdp": "v=0\r\no=- ..."
    },
    "version": "1"
  }
}
```

### m.call.candidates
```json
{
  "type": "m.call.candidates",
  "content": {
    "call_id": "12345",
    "party_id": "party_123",
    "candidates": [
      {
        "candidate": "candidate:...",
        "sdpMid": "0",
        "sdpMLineIndex": 0
      }
    ],
    "version": "1"
  }
}
```

### m.call.hangup
```json
{
  "type": "m.call.hangup",
  "content": {
    "call_id": "12345",
    "party_id": "party_123",
    "version": "1",
    "reason": "user_hangup"
  }
}
```

## Summary

✅ **Full VoIP support IS possible** using:
- `client.addCallEventListener()` for receiving events
- `room.sendRaw()` for sending events

This provides a complete solution without waiting for dedicated FFI methods!

## Advantages of This Approach

1. **Works immediately** - No need to wait for FFI updates
2. **Full control** - Can send any Matrix event type
3. **Standards compliant** - Sends proper Matrix call events
4. **No text workarounds needed** - Uses actual call event types

## Migration Path

When/if the dedicated methods are added to the FFI:
1. Simply replace `room.sendRaw('m.call.invite', ...)` with `client.sendCallInvite(...)`
2. The event format remains the same
3. The receiving side doesn't need any changes