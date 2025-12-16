#!/bin/sh

# Convert one `.svg` file to many `png`s.
# This script now uses PowerShell to crop sprites from the full rendered atlas
# because resvg's --export-id doesn't work properly with this SVG structure.

echo "Exporting sprites from SVG atlas..."

# Check if we're on Windows and can use PowerShell
if command -v powershell >/dev/null 2>&1; then
    powershell -ExecutionPolicy Bypass -File utils/crop_atlas.ps1
else
    echo "Error: PowerShell not found. This script requires PowerShell on Windows."
    echo "Alternatively, use Python with Pillow: python utils/crop_atlas.py"
    exit 1
fi
