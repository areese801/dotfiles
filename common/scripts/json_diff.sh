#!/bin/bash
# Improved json_diff.sh script compatible with macOS

# Check if at least two arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 file1.json file2.json [no_sort]"
    echo "  Set no_sort to 1 to suppress JSON sorting"
    exit 1
fi

FILE1="$1"
FILE2="$2"
NO_SORT="${3:-0}"  # Default to 0 (do sort) if not provided

# Check if both files exist
if [ ! -f "$FILE1" ]; then
    echo "Error: $FILE1 does not exist"
    exit 1
fi

if [ ! -f "$FILE2" ]; then
    echo "Error: $FILE2 does not exist"
    exit 1
fi

# Create temporary files with proper naming for macOS
TEMP_DIR=$(mktemp -d)
TEMP1="${TEMP_DIR}/file1.json"
TEMP2="${TEMP_DIR}/file2.json"

# Format JSON files for better comparison, with optional sorting
if [ "$NO_SORT" -eq 1 ]; then
    # Format without sorting
    jq . "$FILE1" > "$TEMP1"
    jq . "$FILE2" > "$TEMP2"
else
    # Format with sorting
    jq -S . "$FILE1" > "$TEMP1"
    jq -S . "$FILE2" > "$TEMP2"
fi

# Compare the formatted files. Prefer Beyond Compare, then the macOS app bundle,
# then an nvim diff, and finally plain diff as a last resort.
if command -v bcompare &> /dev/null; then
    bcompare "$TEMP1" "$TEMP2"
elif [ -f "/Applications/Beyond Compare.app/Contents/MacOS/bcomp" ]; then
    # Common macOS install location if bcompare isn't in PATH
    "/Applications/Beyond Compare.app/Contents/MacOS/bcomp" "$TEMP1" "$TEMP2"
elif command -v nvim &> /dev/null; then
    echo "Beyond Compare not found; opening an nvim diff instead." >&2
    nvim -d "$TEMP1" "$TEMP2"
else
    echo "Beyond Compare and nvim not found. Using standard diff instead:" >&2
    diff -u "$TEMP1" "$TEMP2"
fi

# Note: We don't immediately clean up the temp files because Beyond Compare needs them
# The files will remain in the temp directory for the comparison session