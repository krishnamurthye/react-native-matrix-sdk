# FFI Implementation Requirements for Matrix Call Events

## Problem Statement
The Matrix Rust SDK's call events are not properly propagating through the FFI layer to React Native. The `CallEventListener` interface is registered but never receives actual Matrix call events, forcing the app to use text-based message workarounds.

## Required FFI Changes

### 1. Event Types to Support
The FFI layer needs to handle these Matrix call event types:
- `m.call.invite` - Incoming call invitation
- `m.call.answer` - Call answered
- `m.call.candidates` - ICE candidates for WebRTC
- `m.call.hangup` - Call terminated
- `m.call.negotiate` - Renegotiation (for network changes)
- `m.call.select_answer` - Multi-device answer selection
- `m.call.reject` - Call rejected

### 2. Current Interface Structure (TypeScript Side)

```typescript
interface CallEventListener {
  onInvite: (roomId: string, callId: string, sender: string, offerSdp: string, callType: CallType, version: number) => void;
  onAnswer: (roomId: string, callId: string, sender: string, answerSdp: string) => void;
  onCandidates: (roomId: string, callId: string, sender: string, candidates: IceCandidate[]) => void;
  onHangup: (roomId: string, callId: string, sender: string, reason?: string) => void;
  onNegotiate: (roomId: string, callId: string, sender: string, offerSdp: string) => void;
  onSelectAnswer: (roomId: string, callId: string, sender: string, selectedPartyId: string) => void;
  onReject: (roomId: string, callId: string, sender: string, reason?: string) => void;
}
```

### 3. FFI Bridge Implementation Requirements

#### Rust Side Changes Needed:

1. **Event Observer Pattern**
   ```rust
   // In the Rust SDK
   pub trait CallEventListener: Send + Sync {
       fn on_call_invite(&self, room_id: String, event: CallInviteEvent);
       fn on_call_answer(&self, room_id: String, event: CallAnswerEvent);
       fn on_call_candidates(&self, room_id: String, event: CallCandidatesEvent);
       fn on_call_hangup(&self, room_id: String, event: CallHangupEvent);
       fn on_call_negotiate(&self, room_id: String, event: CallNegotiateEvent);
       fn on_call_select_answer(&self, room_id: String, event: CallSelectAnswerEvent);
       fn on_call_reject(&self, room_id: String, event: CallRejectEvent);
   }
   ```

2. **Event Subscription in Client**
   ```rust
   impl Client {
       pub fn add_call_event_listener(&self, listener: Box<dyn CallEventListener>) -> ListenerHandle {
           // Subscribe to room events
           // Filter for m.call.* event types
           // Dispatch to appropriate listener methods
       }
   }
   ```

3. **FFI Wrapper for Callback Dispatch**
   ```rust
   #[uniffi::export]
   impl Client {
       pub fn add_call_event_listener(&self, callback: Box<dyn FfiCallEventListener>) -> CallEventHandle {
           // Bridge between Rust trait and FFI callback
       }
   }
   ```

#### React Native Bridge Changes:

1. **Native Module Registration (Android/iOS)**
   - Register event emitters for call events
   - Map Rust callbacks to React Native events

2. **Event Serialization**
   ```kotlin
   // Android example
   fun emitCallEvent(eventType: String, data: ReadableMap) {
       reactContext
           .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
           .emit("MatrixCallEvent", Arguments.createMap().apply {
               putString("type", eventType)
               putMap("data", data)
           })
   }
   ```

### 4. Implementation Steps

1. **Add Event Filtering in Rust SDK**
   - Monitor sync responses for `m.call.*` events
   - Extract events from room timelines
   - Trigger registered callbacks

2. **Create FFI Bindings**
   - Define uniffi interface for CallEventListener
   - Implement callback mechanism for each event type
   - Handle proper memory management for callbacks

3. **Bridge to React Native**
   - Create native modules for Android and iOS
   - Map FFI callbacks to React Native event emitters
   - Ensure proper threading (UI thread for React Native)

4. **TypeScript Integration**
   - Update the SDK TypeScript definitions
   - Ensure proper type safety for event payloads
   - Handle event subscription lifecycle

### 5. Testing Requirements

1. **Unit Tests**
   - Mock call events in Rust
   - Verify callback invocation
   - Test event serialization

2. **Integration Tests**
   - Test with real Matrix server
   - Verify event flow from server → Rust → FFI → React Native
   - Test multiple simultaneous calls

3. **Edge Cases**
   - Handle events for unknown rooms
   - Handle malformed event data
   - Test callback cleanup on disconnect

### 6. Example Implementation Flow

```
Matrix Server
     ↓
Sync Response (m.call.invite)
     ↓
Rust SDK Event Parser
     ↓
CallEventListener Trait Method
     ↓
FFI Callback Bridge
     ↓
Native Module (Android/iOS)
     ↓
React Native Event Emitter
     ↓
JavaScript CallEventListener
     ↓
p2pCallHandler.handleIncomingInvite()
```

### 7. Key Implementation Considerations

1. **Thread Safety**: Ensure callbacks are thread-safe and dispatched on correct threads
2. **Memory Management**: Proper cleanup of callback references to prevent leaks
3. **Error Handling**: Graceful degradation if events fail to propagate
4. **Performance**: Minimize serialization overhead for frequent events (ICE candidates)
5. **Backwards Compatibility**: Maintain compatibility with existing text-based workaround

## Expected Outcome

Once implemented, the `p2pCallHandler` should receive real Matrix call events through the registered `CallEventListener`, eliminating the need for the text-based message workaround and timeline polling.