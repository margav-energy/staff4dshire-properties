@echo off
echo ========================================
echo Staff4dshire Properties - Mobile App
echo ========================================
echo.

cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo Installing Flutter dependencies...
echo.
flutter pub get

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Installation Complete!
    echo ========================================
    echo.
    echo Next steps:
    echo   1. flutter doctor    - Check your setup
    echo   2. flutter devices   - See available devices
    echo   3. flutter run       - Run the app
    echo.
) else (
    echo.
    echo Error: Could not install dependencies
    echo Make sure Flutter is installed and in your PATH
    echo.
)

pause

