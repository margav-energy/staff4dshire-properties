#!/bin/bash
# Script to add Flutter to Git Bash PATH
# Flutter installation: C:\Users\develop\flutter

echo "Setting up Flutter PATH for Git Bash..."
echo ""

FLUTTER_BIN="/c/Users/develop/flutter/bin"

# Check if Flutter exists
if [ ! -d "$FLUTTER_BIN" ]; then
    echo "Error: Flutter not found at $FLUTTER_BIN"
    echo "Please verify your Flutter installation path"
    exit 1
fi

# Check if .bashrc exists
if [ ! -f ~/.bashrc ]; then
    echo "Creating ~/.bashrc..."
    touch ~/.bashrc
fi

# Check if Flutter PATH is already added
if grep -q "flutter/bin" ~/.bashrc; then
    echo "Flutter PATH already configured in ~/.bashrc"
    echo "Updating to use: $FLUTTER_BIN"
    # Remove old Flutter PATH entries
    sed -i '/flutter\/bin/d' ~/.bashrc
fi

# Add Flutter to PATH
echo "" >> ~/.bashrc
echo "# Flutter SDK" >> ~/.bashrc
echo "export PATH=\"\$PATH:$FLUTTER_BIN\"" >> ~/.bashrc

echo "✓ Flutter PATH added to ~/.bashrc"
echo ""
echo "Please run: source ~/.bashrc"
echo "Or restart Git Bash for changes to take effect"
echo ""
echo "Then verify with: flutter --version"

