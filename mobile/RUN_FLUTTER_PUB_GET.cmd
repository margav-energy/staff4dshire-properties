@echo off
echo ========================================
echo Installing Flutter Dependencies
echo ========================================
echo.

REM Change to the directory where this batch file is located
cd /d "%~dp0"

echo Current directory: %CD%
echo.
echo Running: flutter pub get
echo.

flutter pub get

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS! Dependencies installed.
    echo ========================================
    echo.
    echo Next steps:
    echo   flutter doctor    - Check setup
    echo   flutter devices   - See devices
    echo   flutter run       - Run the app
    echo.
) else (
    echo.
    echo ERROR: Installation failed
    echo.
)

pause

