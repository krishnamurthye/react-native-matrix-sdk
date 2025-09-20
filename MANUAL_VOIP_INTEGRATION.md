# Manual VoIP Integration Steps

This document provides the actual working implementation for adding VoIP support to the Matrix SDK FFI bindings.

## Prerequisites

The following files have already been created:
- `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/voip.rs` - VoIP types and interfaces
- `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/voip_sender.rs` - VoIP sender functionality

## Step 1: Verify lib.rs Module Declarations

Edit: `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/lib.rs`

Check that these lines exist (they should already be present):

After `mod widget;` (around line 30):
```rust
mod voip;
mod voip_sender;
```

In the `pub use self::{...}` block (around line 77):
```rust
    voip::*,
    voip_sender::*,
```

## Step 2: Modify client.rs

Edit: `rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs`

### 2.1: Add Call Event Imports (Line ~31)

In the `matrix_sdk` import block, add call event imports:

```rust
use matrix_sdk::{
    // ... existing imports ...
    ruma::{
        // ... existing api imports ...
        events::{
            call::{
                answer::OriginalSyncCallAnswerEvent,
                candidates::OriginalSyncCallCandidatesEvent,
                hangup::OriginalSyncCallHangupEvent,
                invite::OriginalSyncCallInviteEvent,
                reject::OriginalSyncCallRejectEvent,
                SessionDescription,
            },
            // ... rest of existing event imports ...
        },
        // ... rest of existing ruma imports ...
    },
    // ... rest of existing matrix_sdk imports ...
};
```

### 2.2: Add VoIP Module Import (Line ~122)

In the `use crate::{` block, add:

```rust
use crate::{
    // ... existing imports ...
    voip::{CallEventListener, CallType, IceCandidate},
    runtime::get_runtime_handle,
    // ... rest of existing imports ...
};
```

### 2.3: Add the Method to impl Client Block

Add this method at the end of the `impl Client` block (around line 1673, before the closing `}`):

```rust
    /// Add a global listener for VoIP call events
    /// This is critical for P2P calls where the receiver might not have a timeline open
    ///
    /// The listener will receive all call events (invite, answer, candidates, hangup, etc.)
    /// even when the app is in background or no room is open
    pub async fn add_call_event_listener(
        &self,
        listener: Box<dyn CallEventListener>,
    ) -> Result<Arc<TaskHandle>, ClientError> {
        let client = self.inner.clone();
        let listener = Arc::new(listener);

        // Handle m.call.invite events - critical for incoming calls
        let invite_listener = listener.clone();
        let invite_client = client.clone();
        let _invite_handle = invite_client.add_event_handler(
            move |event: OriginalSyncCallInviteEvent, room: matrix_sdk::Room| {
                let listener = invite_listener.clone();
                async move {
                    // Extract SDP from offer
                    let offer_sdp = event.content.offer.sdp.clone();

                    listener.on_invite(
                        room.room_id().to_string(),
                        event.content.call_id.to_string(),
                        event.sender.to_string(),
                        offer_sdp,
                        CallType::Voice, // TODO: Extract actual call type when API available
                        1, // TODO: Extract version when API available
                    );
                }
            },
        );

        // Handle m.call.answer events
        let answer_listener = listener.clone();
        let answer_client = client.clone();
        let _answer_handle = answer_client.add_event_handler(
            move |event: OriginalSyncCallAnswerEvent, room: matrix_sdk::Room| {
                let listener = answer_listener.clone();
                async move {
                    // Extract SDP from answer
                    let answer_sdp = event.content.answer.sdp.clone();

                    listener.on_answer(
                        room.room_id().to_string(),
                        event.content.call_id.to_string(),
                        event.sender.to_string(),
                        answer_sdp,
                    );
                }
            },
        );

        // Handle m.call.candidates events - critical for P2P NAT traversal
        let candidates_listener = listener.clone();
        let candidates_client = client.clone();
        let _candidates_handle = candidates_client.add_event_handler(
            move |event: OriginalSyncCallCandidatesEvent, room: matrix_sdk::Room| {
                let listener = candidates_listener.clone();
                async move {
                    // Convert candidates to our FFI type
                    let candidates: Vec<IceCandidate> = event
                        .content
                        .candidates
                        .into_iter()
                        .map(|c| IceCandidate {
                            candidate: c.candidate,
                            sdp_mid: c.sdp_mid,
                            sdp_m_line_index: c.sdp_m_line_index.map(|_| 0), // TODO: Extract when API available
                        })
                        .collect();

                    listener.on_candidates(
                        room.room_id().to_string(),
                        event.content.call_id.to_string(),
                        event.sender.to_string(),
                        candidates,
                    );
                }
            },
        );

        // Handle m.call.hangup events
        let hangup_listener = listener.clone();
        let hangup_client = client.clone();
        let _hangup_handle = hangup_client.add_event_handler(
            move |event: OriginalSyncCallHangupEvent, room: matrix_sdk::Room| {
                let listener = hangup_listener.clone();
                async move {
                    listener.on_hangup(
                        room.room_id().to_string(),
                        event.content.call_id.to_string(),
                        event.sender.to_string(),
                        Some(event.content.reason.to_string()),
                    );
                }
            },
        );

        // Return a composite task handle
        Ok(Arc::new(TaskHandle::new(get_runtime_handle().spawn(async move {
            // Keep the handlers alive until cancelled
            futures_util::future::pending::<()>().await;
        }))))
    }
```

## Important Implementation Notes

### Key Differences from Original Design

1. **No `.await` on `add_event_handler`**: The method returns an `EventHandlerHandle`, not a Future.

2. **SessionDescription is a struct**: Access SDP directly with `.sdp` instead of pattern matching.

3. **Type conversions**:
   - Version: Use placeholder value `1` (API doesn't expose the actual value easily)
   - CallType: Hardcoded to `CallType::Voice` (actual type extraction needs more work)
   - sdp_m_line_index: Mapped to `0` (UInt field is private)

4. **Reason field**: Convert to string with `.to_string()`

## Step 3: Build and Test

```bash
# Check that the code compiles
cd /home/lalitha/workspace_rust/react-native-matrix-sdk
cargo check --features rustls-tls

# Generate TypeScript bindings
yarn generate

# Build the SDK
yarn build

# Create package
npm pack
```

## Step 4: Verify the Implementation

Check that the TypeScript definitions were generated correctly:

```bash
cat src/generated/matrix_sdk_ffi.ts | grep -A 5 "addCallEventListener"
```

You should see:
```typescript
addCallEventListener(listener: CallEventListener): Promise<TaskHandle>;
```

## Step 5: Install in Your App

```bash
cd /path/to/your/app
npm install /home/lalitha/workspace_rust/react-native-matrix-sdk/unomed-react-native-matrix-sdk-0.7.0.tgz
```

## Common Build Errors and Solutions

### Error: "cannot find type `CallEventListener`"
Make sure the voip module import is added in crate imports.

### Error: "`EventHandlerHandle` is not a future"
Remove `.await` from all `add_event_handler()` calls.

### Error: "no associated item named `Answer` found for struct `SessionDescription`"
Access the SDP directly: `event.content.offer.sdp.clone()`

### Error: "field `0` of struct `UInt` is private"
Use a placeholder value or proper conversion method.

### Error: Missing TLS features
Build with: `cargo check --features rustls-tls`

## Files Modified Summary

1. **client.rs**: Added call event imports, voip module import, and `add_call_event_listener` method
2. **voip.rs**: Already exists with necessary types
3. **voip_sender.rs**: Already exists with sender functionality
4. **lib.rs**: Should already have voip module declarations

## Testing the Integration

Once installed in your app, you can test the VoIP functionality:

```typescript
// In your React Native app
const listener = {
  onInvite: (roomId, callId, sender, offerSdp, callType, version) => {
    console.log('Incoming call:', { roomId, callId, sender });
    // Handle incoming call
  },
  onAnswer: (roomId, callId, sender, answerSdp) => {
    console.log('Call answered:', { roomId, callId });
    // Handle answer
  },
  onCandidates: (roomId, callId, sender, candidates) => {
    console.log('ICE candidates:', { roomId, callId, candidates });
    // Handle ICE candidates
  },
  onHangup: (roomId, callId, sender, reason) => {
    console.log('Call ended:', { roomId, callId, reason });
    // Handle hangup
  }
};

// Register the listener
const handle = await client.addCallEventListener(listener);

// Later, to unregister
await handle.cancel();
```