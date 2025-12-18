@echo off
echo Installing Flutter dependencies...
flutter pub get
if %errorlevel% equ 0 (
    echo.
    echo Dependencies installed successfully!
    echo.
    echo Next steps:
    echo 1. Run 'flutter doctor' to check your setup
    echo 2. Run 'flutter devices' to see available devices
    echo 3. Run 'flutter run' to start the app
) else (
    echo.
    echo Error installing dependencies. Please check Flutter installation.
)
pause

