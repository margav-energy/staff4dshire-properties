@echo off
echo ========================================
echo Running Flutter Web Server
echo ========================================
echo.

cd /d "%~dp0"

echo This will start a web server instead of launching Chrome directly.
echo You'll need to open the URL manually in your browser.
echo.

flutter run -d web-server

if %errorlevel% neq 0 (
    echo.
    echo Error: Could not start web server
    echo.
    pause
)

