#!/bin/bash

# Script to verify all required symbols are present in the built libraries
# This will help identify missing symbols before deployment

echo "==========================================="
echo "Symbol Verification for React Native Matrix SDK"
echo "==========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
GENERATED_TS="/home/lalitha/workspace_rust/react-native-matrix-sdk/src/generated/matrix_sdk_ffi.ts"
ANDROID_LIB="/home/lalitha/workspace_rust/react-native-matrix-sdk/rust_modules/matrix-rust-sdk/bindings/matrix-sdk-ffi/android-libs/arm64-v8a/libmatrix_sdk_ffi.so"

if [ ! -f "$GENERATED_TS" ]; then
    echo -e "${RED}Error: Generated TypeScript file not found at $GENERATED_TS${NC}"
    exit 1
fi

if [ ! -f "$ANDROID_LIB" ]; then
    echo -e "${RED}Error: Android library not found at $ANDROID_LIB${NC}"
    echo "Please build the library first with: cargo ndk build --release"
    exit 1
fi

echo "Extracting expected symbols from TypeScript bindings..."
# Extract all uniffi symbols from the generated TypeScript
EXPECTED_SYMBOLS=$(grep -o "uniffi_matrix_sdk_ffi_fn_[a-z_]*" "$GENERATED_TS" | sort -u)
EXPECTED_COUNT=$(echo "$EXPECTED_SYMBOLS" | wc -l)

echo "Extracting actual symbols from Android library..."
# Extract all uniffi function symbols from the built library
ACTUAL_SYMBOLS=$(nm -D "$ANDROID_LIB" | grep "T uniffi_matrix_sdk_ffi_fn_" | awk '{print $3}' | sort -u)
ACTUAL_COUNT=$(echo "$ACTUAL_SYMBOLS" | wc -l)

echo ""
echo "Summary:"
echo "  Expected symbols: $EXPECTED_COUNT"
echo "  Actual symbols: $ACTUAL_COUNT"
echo ""

# Find missing symbols
echo "Checking for missing symbols..."
MISSING_SYMBOLS=""
MISSING_COUNT=0

while IFS= read -r symbol; do
    if ! echo "$ACTUAL_SYMBOLS" | grep -q "^$symbol$"; then
        MISSING_SYMBOLS="$MISSING_SYMBOLS$symbol\n"
        ((MISSING_COUNT++))
    fi
done <<< "$EXPECTED_SYMBOLS"

if [ $MISSING_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All expected symbols are present!${NC}"
    echo ""
    echo -e "${GREEN}Your libraries are ready for deployment!${NC}"
else
    echo -e "${RED}✗ Found $MISSING_COUNT missing symbols:${NC}"
    echo ""
    echo -e "$MISSING_SYMBOLS" | while IFS= read -r symbol; do
        if [ ! -z "$symbol" ]; then
            # Extract the type and name from the symbol
            TYPE=$(echo "$symbol" | sed 's/uniffi_matrix_sdk_ffi_fn_//' | cut -d_ -f1)
            NAME=$(echo "$symbol" | sed "s/uniffi_matrix_sdk_ffi_fn_${TYPE}_//")
            echo -e "  ${YELLOW}$symbol${NC}"
            echo -e "    Type: $TYPE, Name: $NAME"
        fi
    done
    echo ""
    echo -e "${RED}These symbols need to be added before deployment!${NC}"
    
    # Group missing symbols by type
    echo ""
    echo "Missing symbols grouped by type:"
    echo -e "$MISSING_SYMBOLS" | while IFS= read -r symbol; do
        if [ ! -z "$symbol" ]; then
            echo "$symbol" | sed 's/uniffi_matrix_sdk_ffi_fn_//' | cut -d_ -f1
        fi
    done | sort | uniq -c | while read count type; do
        echo "  $type: $count missing"
    done
fi

# Also check for extra symbols (optional)
echo ""
echo "Checking for extra symbols (in library but not in TypeScript)..."
EXTRA_COUNT=0
while IFS= read -r symbol; do
    if ! echo "$EXPECTED_SYMBOLS" | grep -q "^$symbol$"; then
        ((EXTRA_COUNT++))
    fi
done <<< "$ACTUAL_SYMBOLS"

if [ $EXTRA_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Note: Found $EXTRA_COUNT extra symbols in library (this is usually OK)${NC}"
fi

echo ""
echo "==========================================="
exit $MISSING_COUNT