# Step-by-Step: Adding VoIP to client.rs

## File to Edit
`/home/lalitha/workspace_rust/react-native-matrix-sdk/rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs`

## Step 1: Add Call Event Imports (Line ~31)

In the `matrix_sdk` import block, add call event imports inside the events block:

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

## Step 2: Add VoIP Module Import (Line ~122)

In the `use crate::{` block, add the voip import:

```rust
use crate::{
    // ... existing imports ...
    voip::{CallEventListener, CallType, IceCandidate},
    runtime::get_runtime_handle,
    // ... rest of existing imports ...
};
```

## Step 3: Add the Method (Line ~1673)

Add the method at the end of the `impl Client` block, right before the closing `}`:

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
                        CallType::Voice, // TODO: Extract actual call type from event when available
                        1, // TODO: Extract version when API is available
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
                            sdp_m_line_index: c.sdp_m_line_index.map(|_| 0), // TODO: Extract actual value when API is available
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
}
```

## Important Notes About the Implementation

### Key Differences from Original Design

1. **No `.await` on `add_event_handler`**: The method returns an `EventHandlerHandle`, not a Future, so we don't await it.

2. **SessionDescription is a struct**: Access SDP directly with `.sdp` instead of pattern matching on enum variants.

3. **Version field**: The version field is not directly accessible as a u32, so we use a placeholder value of 1.

4. **Call type**: Currently hardcoded to `CallType::Voice` as the actual call type is not easily extractable from the event.

5. **sdp_m_line_index**: The UInt type doesn't have a public `.0` field, so we map to 0 as a placeholder.

6. **Reason field**: The hangup reason is converted to string with `.to_string()`.

## Step 4: Build

```bash
cd /home/lalitha/workspace_rust/react-native-matrix-sdk
cargo check --features rustls-tls
yarn generate
yarn build
```

## Troubleshooting Common Errors

### Error: "cannot find type `CallEventListener`"
**Fix**: Make sure you added the import in Step 2:
```rust
use crate::voip::{CallEventListener, CallType, IceCandidate};
```

### Error: "no method named `add_event_handler`"
**Fix**: The client needs to be cloned first:
```rust
let client = self.inner.clone();
```

### Error: "`EventHandlerHandle` is not a future"
**Fix**: Remove `.await` from the `add_event_handler()` calls.

### Error: "no associated item named `Answer` found for struct `SessionDescription`"
**Fix**: Access the SDP directly:
```rust
let offer_sdp = event.content.offer.sdp.clone();
```

### Error: "field `0` of struct `UInt` is private"
**Fix**: Use a placeholder or find the appropriate conversion method:
```rust
sdp_m_line_index: c.sdp_m_line_index.map(|_| 0)
```

## Verification

After building, check the generated TypeScript:

```bash
cat src/generated/matrix_sdk_ffi.ts | grep -A 5 "addCallEventListener"
```

You should see:
```typescript
addCallEventListener(listener: CallEventListener): Promise<TaskHandle>;
```

## Files Modified

1. `/home/lalitha/workspace_rust/react-native-matrix-sdk/rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/client.rs`
   - Added call event imports
   - Added voip module import
   - Added `add_call_event_listener` method

2. `/home/lalitha/workspace_rust/react-native-matrix-sdk/rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/voip.rs`
   - Already exists with the necessary types

3. `/home/lalitha/workspace_rust/react-native-matrix-sdk/rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/src/lib.rs`
   - The voip module should already be declared and exported