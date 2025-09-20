# VoIP Implementation - ACTUAL Current State

## ⚠️ CRITICAL: Missing Send Methods

After thorough investigation, here's the **actual** state of VoIP support in the React Native Matrix SDK:

## ✅ What EXISTS (Can Receive Events)

### 1. Call Event Listener Registration
```typescript
// This EXISTS and works
client.addCallEventListener(listener: CallEventListener): Promise<CallEventListenerHandle>
```

### 2. CallEventListener Interface
```typescript
// This interface EXISTS for receiving events
interface CallEventListener {
  onInvite(roomId: string, callId: string, sender: string, offerSdp: string, callType: CallType, version: number): void;
  onAnswer(roomId: string, callId: string, sender: string, answerSdp: string): void;
  onCandidates(roomId: string, callId: string, sender: string, candidates: Array<IceCandidate>): void;
  onHangup(roomId: string, callId: string, sender: string, reason?: string): void;
  onNegotiate(roomId: string, callId: string, sender: string, offerSdp: string): void;
  onSelectAnswer(roomId: string, callId: string, sender: string, selectedPartyId: string): void;
  onReject(roomId: string, callId: string, sender: string, reason?: string): void;
}
```

### 3. Types That Exist
```typescript
// These types are defined
- CallType (enum: Voice | Video)
- IceCandidate (type)
- OutgoingCallInvite (type)
- OutgoingCallAnswer (type)
- OutgoingCallCandidates (type)
- OutgoingCallHangup (type)
```

## ❌ What DOES NOT EXIST (Cannot Send Events)

### Missing Client Methods
```typescript
// These methods DO NOT EXIST in the Client class:
client.sendCallInvite()    // ❌ NOT IMPLEMENTED
client.sendCallAnswer()    // ❌ NOT IMPLEMENTED
client.sendCallCandidates() // ❌ NOT IMPLEMENTED
client.sendCallHangup()    // ❌ NOT IMPLEMENTED
```

## 🔍 What Actually Exists Instead

### Call Notification Methods (Different Purpose)
```typescript
// These exist but are for RTC session notifications, NOT for call events
client.sendCallNotification(
  callId: string,
  application: RtcApplicationType,
  notifyType: NotifyType,
  mentions: Mentions
): Promise<void>

client.sendCallNotificationIfNeeded(): Promise<boolean>
```

These are for notifying room members about an RTC session, not for sending actual Matrix call events (`m.call.*`).

## 📊 Summary Table

| Feature | Status | Notes |
|---------|--------|-------|
| **Receiving Call Events** | ✅ Implemented | `addCallEventListener()` works |
| **CallEventListener interface** | ✅ Implemented | All 7 callbacks defined |
| **VoIP Types** | ✅ Defined | Types exist but can't be used to send |
| **Sending Call Invites** | ❌ Missing | No `sendCallInvite()` method |
| **Sending Call Answers** | ❌ Missing | No `sendCallAnswer()` method |
| **Sending ICE Candidates** | ❌ Missing | No `sendCallCandidates()` method |
| **Sending Call Hangups** | ❌ Missing | No `sendCallHangup()` method |
| **RTC Notifications** | ✅ Implemented | Different purpose than call events |

## 🚨 The Problem

1. **We can LISTEN for call events** - If another Matrix client sends proper `m.call.*` events, our app will receive them through the `CallEventListener`

2. **We CANNOT SEND call events** - There's no way to send standard Matrix call events through the SDK

3. **Text-based workaround is still necessary** - Without the ability to send proper call events, the current text-message workaround must remain

## 🛠️ What Needs to Be Implemented

The Rust SDK FFI layer needs to add these methods to the Client class:

```rust
impl Client {
    // Send m.call.invite event
    pub async fn send_call_invite(
        &self,
        room_id: String,
        invite: OutgoingCallInvite
    ) -> Result<()>

    // Send m.call.answer event
    pub async fn send_call_answer(
        &self,
        room_id: String,
        answer: OutgoingCallAnswer
    ) -> Result<()>

    // Send m.call.candidates event
    pub async fn send_call_candidates(
        &self,
        room_id: String,
        candidates: OutgoingCallCandidates
    ) -> Result<()>

    // Send m.call.hangup event
    pub async fn send_call_hangup(
        &self,
        room_id: String,
        hangup: OutgoingCallHangup
    ) -> Result<()>
}
```

## 🔄 Alternative: Using Room's send() Method

As a workaround, we might be able to use the Room's generic `send()` method to send custom events:

```typescript
// This might work as a workaround
const room = client.getRoom(roomId);
const callInviteEvent = {
  type: "m.call.invite",
  content: {
    call_id: callId,
    offer: { type: "offer", sdp: offerSdp },
    version: 1,
    lifetime: 60000
  }
};

// Need to check if this works
await room.send(callInviteEvent);
```

However, this needs investigation to see if the Room's `send()` method accepts custom event types.

## 📝 Conclusion

The VoIP implementation is **half complete**:
- ✅ Can receive and process call events from other clients
- ❌ Cannot send call events to initiate or respond to calls
- 🔧 Text-based workaround remains necessary until send methods are implemented

**The FFI agent's documentation was incorrect** - it assumed the send methods existed when they don't. This is a critical gap that needs to be addressed in the Rust SDK's FFI layer.