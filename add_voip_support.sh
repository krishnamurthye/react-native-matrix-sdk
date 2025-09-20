#!/bin/bash

# Script to add VoIP support to the react-native-matrix-sdk
# This script ensures VoIP changes are included in matrix-rust-sdk.patch

echo "Adding VoIP support to react-native-matrix-sdk..."

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "rust_modules" ]; then
    echo "Error: Please run this script from the react-native-matrix-sdk root directory"
    exit 1
fi

# Backup the original patch if not already done
if [ ! -f "matrix-rust-sdk.patch.backup" ]; then
    cp matrix-rust-sdk.patch matrix-rust-sdk.patch.backup
    echo "Backed up original patch to matrix-rust-sdk.patch.backup"
fi

# Check if VoIP changes are already in the patch
if grep -q "add_call_event_listener" matrix-rust-sdk.patch; then
    echo "✅ VoIP support already exists in matrix-rust-sdk.patch"
    echo "The patch file will be preserved when running 'yarn generate'"
    exit 0
fi

echo "VoIP changes not found in matrix-rust-sdk.patch"
echo "Attempting to add them..."

# Check if voip-additions.patch exists and has content
if [ -f "voip-additions.patch" ] && [ -s "voip-additions.patch" ]; then
    echo "Found voip-additions.patch, appending to matrix-rust-sdk.patch..."
    cat voip-additions.patch >> matrix-rust-sdk.patch
    echo "✅ VoIP support added to matrix-rust-sdk.patch"
else
    echo "Creating voip-additions.patch from current changes..."

    # Save current directory
    ORIGINAL_DIR=$(pwd)

    # Go to the rust SDK directory
    cd rust_modules/matrix-rust-sdk

    # Stage all changes
    git add -A

    # Create a patch of all staged changes
    git diff --cached > ../../voip-additions.patch

    # Go back to original directory
    cd "$ORIGINAL_DIR"

    # Check if the patch was created successfully
    if [ -f "voip-additions.patch" ] && [ -s "voip-additions.patch" ]; then
        # Append to the main patch file
        cat voip-additions.patch >> matrix-rust-sdk.patch
        echo "✅ VoIP support added to matrix-rust-sdk.patch"
    else
        echo "❌ Error: Failed to create voip-additions.patch"
        echo "Please ensure you have made the VoIP changes to the code first."
        exit 1
    fi
fi

# Verify the patch was updated
if grep -q "add_call_event_listener" matrix-rust-sdk.patch; then
    echo ""
    echo "============================================"
    echo "✅ SUCCESS! VoIP support has been added to matrix-rust-sdk.patch"
    echo ""
    echo "The VoIP changes are now permanent and will be preserved when running:"
    echo "  - yarn generate"
    echo "  - ubrn checkout"
    echo ""
    echo "Next steps:"
    echo "1. Run: yarn generate"
    echo "2. Run: yarn build"
    echo "3. Run: npm pack"
    echo "4. Install the generated .tgz file in your app"
    echo "============================================"
else
    echo "❌ Warning: Could not verify VoIP changes in matrix-rust-sdk.patch"
    echo "Please check the patch file manually"
fi