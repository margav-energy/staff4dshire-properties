@echo off
echo Copying notification sound to web folders...

REM Copy to admin app web folder
if not exist "apps\admin_app\web\assets" mkdir "apps\admin_app\web\assets"
copy "apps\admin_app\assets\notification_sound.mp3" "apps\admin_app\web\assets\notification_sound.mp3"
if %errorlevel% equ 0 (
    echo ✅ Copied to apps\admin_app\web\assets\notification_sound.mp3
) else (
    echo ❌ Failed to copy to admin app web folder
)

REM Copy to staff app web folder
if not exist "apps\staff_app\web\assets" mkdir "apps\staff_app\web\assets"
copy "apps\staff_app\assets\notification_sound.mp3" "apps\staff_app\web\assets\notification_sound.mp3"
if %errorlevel% equ 0 (
    echo ✅ Copied to apps\staff_app\web\assets\notification_sound.mp3
) else (
    echo ❌ Failed to copy to staff app web folder
)

echo.
echo Done! The notification sound has been copied to web folders.
echo.
echo IMPORTANT: You need to rebuild your Flutter web app for the changes to take effect:
echo   cd apps\admin_app
echo   flutter clean
echo   flutter build web
echo.
echo   OR for staff app:
echo   cd apps\staff_app
echo   flutter clean
echo   flutter build web
echo.


