# Implementation Plan: Adding Call Event Handlers to React Native Matrix SDK

## Current State Analysis

### What Already Works
1. **Rust SDK has event handlers**: The underlying Rust SDK already uses `client.add_event_handler()` internally (see `client.rs` lines 252, 266)
2. **Callback interfaces exist**: The FFI layer supports callback interfaces via `#[matrix_sdk_ffi_macros::export(callback_interface)]`
3. **Call events are recognized**: `CallInvite` and `CallNotify` are already defined in `TimelineItemContent`
4. **Timeline listeners work**: `TimelineListener` successfully delivers events to JavaScript

### What's Missing
- No direct exposure of `add_event_handler()` to JavaScript
- No way to register global event listeners (must use per-room timeline)
- No filtering by event type at the SDK level

## Implementation Options

### Option 1: Full Event Handler Support (2-3 weeks)
Add complete event handler support matching the native Rust SDK:

```rust
// In client.rs
#[matrix_sdk_ffi_macros::export]
impl Client {
    pub async fn add_event_handler(
        &self,
        event_type: EventType,
        handler: Box<dyn EventHandler>
    ) -> Arc<TaskHandle> {
        // Implementation
    }
}

#[matrix_sdk_ffi_macros::export(callback_interface)]
pub trait EventHandler: SyncOutsideWasm + SendOutsideWasm {
    fn on_event(&self, event: EventContent, room_id: String);
}
```

**Pros:**
- Complete parity with Rust SDK
- Supports all event types
- Clean architecture

**Cons:**
- Requires mapping ALL Matrix event types to FFI
- Large implementation effort
- Complex testing requirements

### Option 2: Call-Only Event Handlers (3-5 days) ⭐ RECOMMENDED
Add focused support for VoIP call events:

```rust
// In bindings/matrix-sdk-ffi/src/client.rs
#[matrix_sdk_ffi_macros::export]
impl Client {
    pub async fn add_call_event_listener(
        &self,
        listener: Box<dyn CallEventListener>
    ) -> Result<Arc<TaskHandle>, ClientError> {
        let client = self.inner.clone();
        let listener = Arc::new(listener);

        // Listen for m.call.invite events
        let invite_listener = listener.clone();
        client.add_event_handler(move |event: OriginalSyncCallInviteEvent| async move {
            invite_listener.on_invite(
                event.room_id.to_string(),
                event.content.call_id.to_string(),
                event.sender.to_string(),
                serde_json::to_string(&event.content.offer).unwrap_or_default()
            );
        });

        // Listen for m.call.answer events
        let answer_listener = listener.clone();
        client.add_event_handler(move |event: OriginalSyncCallAnswerEvent| async move {
            answer_listener.on_answer(
                event.room_id.to_string(),
                event.content.call_id.to_string(),
                event.sender.to_string(),
                serde_json::to_string(&event.content.answer).unwrap_or_default()
            );
        });

        // Similar for candidates and hangup...

        Ok(Arc::new(TaskHandle { /* ... */ }))
    }
}

// In bindings/matrix-sdk-ffi/src/voip.rs (new file)
#[matrix_sdk_ffi_macros::export(callback_interface)]
pub trait CallEventListener: SyncOutsideWasm + SendOutsideWasm {
    fn on_invite(&self, room_id: String, call_id: String, sender: String, offer: String);
    fn on_answer(&self, room_id: String, call_id: String, sender: String, answer: String);
    fn on_candidates(&self, room_id: String, call_id: String, sender: String, candidates: String);
    fn on_hangup(&self, room_id: String, call_id: String, sender: String, reason: Option<String>);
}
```

**Pros:**
- Solves immediate VoIP needs
- Much simpler implementation
- Can be extended later
- Clear, focused API

**Cons:**
- Only handles call events
- Not a general solution

### Option 3: Timeline-Based Optimization (1-2 days)
Keep using Timeline but add event type filtering:

```rust
// In timeline/mod.rs
#[matrix_sdk_ffi_macros::export]
impl Timeline {
    pub async fn add_filtered_listener(
        &self,
        event_types: Vec<String>, // ["m.call.invite", "m.call.answer"]
        listener: Box<dyn FilteredTimelineListener>
    ) -> Arc<TaskHandle> {
        // Only send matching events to listener
    }
}
```

**Pros:**
- Minimal changes needed
- Works with existing architecture
- Quick to implement

**Cons:**
- Still requires timeline per room
- Not truly global event handling

## Recommended Approach

**Phase 1 (Immediate):** Implement Option 2 - Call-Only Event Handlers
- Create `voip.rs` with `CallEventListener` trait
- Add `add_call_event_listener()` to Client
- Auto-generate TypeScript bindings
- Test with your existing VoIP implementation

**Phase 2 (Future):** Extend to Option 1 if needed
- Once call events work, evaluate need for other event types
- Incrementally add support for more events

## Implementation Steps for Option 2

1. **Create VoIP module** (`rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/voip.rs`):
   - Define `CallEventListener` trait
   - Define call event data structures

2. **Modify Client** (`client.rs`):
   - Import call event types from ruma
   - Add `add_call_event_listener()` method
   - Wire up event handlers to the listener

3. **Update module exports** (`lib.rs`):
   - Export the new VoIP module

4. **Rebuild bindings**:
   ```bash
   cd /home/lalitha/workspace_rust/react-native-matrix-sdk
   yarn generate
   yarn build
   ```

5. **Use in React Native**:
   ```typescript
   const callListener = {
     onInvite: (roomId, callId, sender, offer) => {
       console.log('Incoming call!', { roomId, callId, sender });
       // Handle WebRTC offer
     },
     onAnswer: (roomId, callId, sender, answer) => {
       // Handle WebRTC answer
     },
     onCandidates: (roomId, callId, sender, candidates) => {
       // Handle ICE candidates
     },
     onHangup: (roomId, callId, sender, reason) => {
       // Handle call end
     }
   };

   const handle = await client.addCallEventListener(callListener);
   // Later: handle.cancel() to stop listening
   ```

## Benefits Over Current Approach

1. **No polling needed** - Events pushed directly
2. **No message parsing** - SDK handles event deserialization
3. **Global scope** - One listener for all rooms
4. **Better performance** - Native routing, no JS filtering
5. **Type safety** - Strongly typed event data
6. **Proper VoIP events** - Use actual `m.call.*` events instead of text messages

## Next Steps

1. Review this plan
2. Create a feature branch in the SDK repo
3. Implement the FFI changes
4. Test with your app
5. Submit PR to upstream if desired

This approach gives you proper VoIP event handling in 3-5 days of work, solving your immediate needs while leaving room for future expansion.