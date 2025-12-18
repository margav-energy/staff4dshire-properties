#!/bin/bash
# Install Flutter dependencies using the Flutter installation at C:\Users\develop\flutter

FLUTTER_PATH="/c/Users/develop/flutter/bin/flutter"

echo "Installing Flutter dependencies..."
echo "Using Flutter at: $FLUTTER_PATH"

# Check if Flutter exists at the path
if [ ! -f "$FLUTTER_PATH" ]; then
    echo "Error: Flutter not found at $FLUTTER_PATH"
    echo "Please verify your Flutter installation path"
    exit 1
fi

# Run flutter pub get
"$FLUTTER_PATH" pub get

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Dependencies installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Run 'flutter doctor' to check your setup"
    echo "  2. Run 'flutter devices' to see available devices"
    echo "  3. Run 'flutter run' to start the app"
else
    echo ""
    echo "✗ Error installing dependencies"
    exit 1
fi

