#!/bin/bash

# Test script to verify Matrix sync is working
# This creates a test room and sends messages to verify sync

set -e

echo "=========================================="
echo "🔄 MATRIX SYNC VERIFICATION TEST"
echo "=========================================="
echo ""

# Your local Dendrite server
SERVER="http://localhost:8008"
USER_ID="@pixel:12D3KooWHXwDxE2t5xA85kf5H4xVdEwnGWFMd9hoKtko4geCZcTm"

echo "📝 Test requires access token. Please provide it:"
read -s ACCESS_TOKEN
echo ""

echo "1️⃣ Creating a test room..."
ROOM_RESPONSE=$(curl -s -X POST "${SERVER}/_matrix/client/r0/createRoom" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sync Test Room",
    "topic": "Testing normal sync functionality",
    "preset": "private_chat"
  }')

ROOM_ID=$(echo $ROOM_RESPONSE | grep -o '"room_id":"[^"]*' | cut -d'"' -f4)

if [ -z "$ROOM_ID" ]; then
    echo "❌ Failed to create room"
    echo "Response: $ROOM_RESPONSE"
    exit 1
fi

echo "✅ Room created: $ROOM_ID"
echo ""

# Send test messages
echo "2️⃣ Sending test messages..."
for i in {1..5}; do
    MSG_RESPONSE=$(curl -s -X PUT "${SERVER}/_matrix/client/r0/rooms/${ROOM_ID}/send/m.room.message/test_${i}" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"msgtype\": \"m.text\",
        \"body\": \"Test message ${i} - Sync verification at $(date)\"
      }")
    
    EVENT_ID=$(echo $MSG_RESPONSE | grep -o '"event_id":"[^"]*' | cut -d'"' -f4)
    if [ -n "$EVENT_ID" ]; then
        echo "   ✅ Message ${i} sent: $EVENT_ID"
    else
        echo "   ❌ Failed to send message ${i}"
    fi
    sleep 1
done

echo ""
echo "3️⃣ Performing sync to get messages..."
SYNC_RESPONSE=$(curl -s -X GET "${SERVER}/_matrix/client/r0/sync?timeout=5000" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

# Check if room appears in sync
if echo "$SYNC_RESPONSE" | grep -q "$ROOM_ID"; then
    echo "✅ Room found in sync response!"
    
    # Count messages in the room
    MSG_COUNT=$(echo "$SYNC_RESPONSE" | grep -o "Test message" | wc -l)
    echo "📊 Found $MSG_COUNT test messages in sync"
else
    echo "❌ Room not found in sync response"
fi

echo ""
echo "4️⃣ Getting room messages directly..."
MESSAGES_RESPONSE=$(curl -s -X GET "${SERVER}/_matrix/client/r0/rooms/${ROOM_ID}/messages?limit=10" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

MSG_COUNT=$(echo "$MESSAGES_RESPONSE" | grep -o "Test message" | wc -l)
echo "📊 Found $MSG_COUNT messages via messages API"

echo ""
echo "=========================================="
echo "📱 CHECK YOUR APP NOW!"
echo "=========================================="
echo ""
echo "If sync is working properly, you should see:"
echo "1. The new room 'Sync Test Room' appear in your room list"
echo "2. The 5 test messages in that room"
echo "3. The sync indicator should show activity"
echo ""
echo "Room ID for debugging: $ROOM_ID"
echo ""