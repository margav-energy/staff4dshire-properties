@echo off
echo ========================================
echo Running Flutter App on Edge
echo ========================================
echo.

cd /d "%~dp0"

echo Trying to launch on Microsoft Edge...
echo If Edge is not available, use RUN_WEB_SERVER.cmd instead
echo.

flutter run -d edge

if %errorlevel% neq 0 (
    echo.
    echo Edge not available. Try: flutter run -d web-server
    echo.
    pause
)

