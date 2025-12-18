@echo off
echo ========================================
echo Staff4dshire Properties - Mobile App
echo ========================================
echo.

REM Change to the directory where this batch file is located
cd /d "%~dp0"

echo Current directory: %CD%
echo.

echo Available devices:
flutter devices
echo.

echo ========================================
echo Starting app on Chrome...
echo Press Ctrl+C to stop the app
echo ========================================
echo.

flutter run -d chrome

if %errorlevel% neq 0 (
    echo.
    echo Error: Could not run the app
    echo Try: flutter devices
    echo.
    pause
)

