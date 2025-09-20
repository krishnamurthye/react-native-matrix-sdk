# VoIP Encryption Guide for Secure P2P Communication

## 🔐 Critical Security Information

### YES, `sendRaw()` RESPECTS Room Encryption!

The Matrix Rust SDK's `sendRaw()` method **automatically encrypts** events when sending to encrypted rooms. This is crucial for your secure P2P application.

## How It Works

### 1. Room Encryption Check
```typescript
const room = client.getRoom(roomId);

// Check if room is encrypted
const isEncrypted = await room.isEncrypted();
const encryptionState = room.encryptionState();

console.log(`Room encrypted: ${isEncrypted}`);
console.log(`Encryption state: ${encryptionState}`);
```

### 2. Automatic Encryption with sendRaw()

When you call `room.sendRaw()`:
- If room is **encrypted**: The SDK automatically encrypts the content before sending
- If room is **not encrypted**: The content is sent as plaintext
- **You don't need to manually encrypt anything**

```typescript
// This will be automatically encrypted in encrypted rooms
await room.sendRaw('m.call.invite', JSON.stringify({
  call_id: callId,
  offer: { type: 'offer', sdp: offerSdp },
  // ... other fields
}));
```

## What Gets Encrypted

In an encrypted room, the Matrix SDK encrypts:
- ✅ **Event content** - The entire JSON content of your call events
- ✅ **Call signaling data** - offer/answer SDPs, ICE candidates
- ✅ **Metadata** - Call IDs, party IDs, etc.

What remains unencrypted (by design):
- ❌ Event type (e.g., `m.call.invite`) - Needed for routing
- ❌ Sender information - Needed for verification
- ❌ Room ID - Needed for delivery

## Secure P2P VoIP Implementation

```typescript
class SecureVoIPHandler implements CallEventListener {
  private client: Client;

  async initializeSecureCall(roomId: string): Promise<void> {
    const room = this.client.getRoom(roomId);

    // 1. Verify room is encrypted
    const isEncrypted = await room.isEncrypted();
    if (!isEncrypted) {
      throw new Error('Cannot make secure calls in unencrypted rooms');
    }

    // 2. Check encryption state
    const encryptionState = room.encryptionState();
    console.log(`Encryption state: ${encryptionState}`);

    // 3. Register for encrypted call events
    await this.client.addCallEventListener(this);
  }

  async sendSecureCallInvite(
    roomId: string,
    callId: string,
    offerSdp: string,
    callType: CallType
  ): Promise<void> {
    const room = this.client.getRoom(roomId);

    // Verify encryption before sending
    if (!(await room.isEncrypted())) {
      throw new Error('Room must be encrypted for secure calls');
    }

    const content = {
      call_id: callId,
      party_id: this.generatePartyId(),
      offer: {
        type: 'offer',
        sdp: offerSdp  // This SDP will be encrypted
      },
      version: '1',
      lifetime: 60000,
      "m.call.type": callType === CallType.Video ? "video" : "voice"
    };

    // SDK automatically encrypts this in encrypted rooms
    await room.sendRaw('m.call.invite', JSON.stringify(content));
    console.log('✅ Encrypted call invite sent');
  }

  // Receiving encrypted events
  onInvite(
    roomId: string,
    callId: string,
    sender: string,
    offerSdp: string,  // Already decrypted by SDK
    callType: CallType,
    version: number
  ): void {
    // The SDK has already decrypted this for you
    console.log('🔓 Received and decrypted call invite');
    // Process the decrypted offer SDP
  }

  // Similar for other callbacks - all automatically decrypted
}
```

## End-to-End Encryption Flow

```
Sender Side:
1. App calls room.sendRaw('m.call.invite', content)
2. SDK checks room.isEncrypted() internally
3. If encrypted: SDK encrypts content using Megolm
4. Encrypted event sent to server

Server:
- Sees encrypted blob (cannot read content)
- Routes to recipients

Receiver Side:
1. SDK receives encrypted event
2. SDK decrypts using Megolm session keys
3. CallEventListener.onInvite() called with decrypted content
4. App receives plain SDP and call data
```

## Security Best Practices

### 1. Always Verify Room Encryption
```typescript
async function ensureSecureRoom(room: Room): Promise<void> {
  if (!(await room.isEncrypted())) {
    throw new Error('Room must be encrypted for secure communication');
  }
}
```

### 2. Enable Encryption for New Rooms
```typescript
// When creating a room for P2P calls
const roomId = await client.createRoom({
  name: 'Secure P2P Call',
  isDirect: true,
  initialState: [
    {
      type: 'm.room.encryption',
      content: {
        algorithm: 'm.megolm.v1.aes-sha2'
      }
    }
  ]
});
```

### 3. Handle Encryption Errors
```typescript
try {
  await room.sendRaw('m.call.invite', content);
} catch (error) {
  if (error.message.includes('encryption')) {
    console.error('Encryption error - may need to verify devices');
    // Handle key verification flow
  }
}
```

### 4. Verify User Devices (Important for P2P)
```typescript
// Get encryption info for the client
const encryption = client.encryption();

// Verify other user's device for maximum security
async function verifyUserDevice(userId: string): Promise<void> {
  // Implement device verification flow
  // This ensures you're really talking to who you think
}
```

## Additional Security Layers

Beyond Matrix encryption, for P2P calls you also have:

1. **WebRTC DTLS-SRTP**: Encrypts the actual media streams
2. **ICE Candidates**: Can be encrypted in Matrix events
3. **TURN Server Auth**: Use authenticated TURN servers

```typescript
const peerConnection = new RTCPeerConnection({
  iceServers: [
    {
      urls: 'turns:your-turn-server.com:443',
      username: 'secure-username',
      credential: 'secure-password'
    }
  ],
  // Force encryption for media
  bundlePolicy: 'max-bundle',
  rtcpMuxPolicy: 'require'
});
```

## Summary for Your P2P Application

✅ **`sendRaw()` automatically encrypts in encrypted rooms**
✅ **Call events (invite, answer, candidates) are E2E encrypted**
✅ **Media streams are separately encrypted via WebRTC DTLS-SRTP**
✅ **Full end-to-end encryption for signaling and media**

Your P2P application will have:
- **Encrypted signaling** via Matrix Megolm encryption
- **Encrypted media** via WebRTC DTLS-SRTP
- **No server can intercept or decode your calls**

This provides military-grade security for your P2P VoIP calls!