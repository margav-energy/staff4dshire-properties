@echo off
echo ========================================
echo Fixing Issues and Running App
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Adding web support...
C:\Users\develop\flutter\bin\flutter.bat create . --platforms=web

if %errorlevel% neq 0 (
    echo Error adding web support
    pause
    exit /b 1
)

echo.
echo Step 2: Running the app on Chrome...
echo.

C:\Users\develop\flutter\bin\flutter.bat run -d chrome

pause

