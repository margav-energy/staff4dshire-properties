@echo off
echo ========================================
echo Adding Web Support to Flutter Project
echo ========================================
echo.

cd /d "%~dp0"

echo Current directory: %CD%
echo.
echo Running: flutter create .
echo This will add web support to your project...
echo.

C:\Users\develop\flutter\bin\flutter.bat create .

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Web support added successfully!
    echo ========================================
    echo.
    echo You can now run: flutter run -d chrome
    echo.
) else (
    echo.
    echo Error: Could not add web support
    echo.
)

pause

