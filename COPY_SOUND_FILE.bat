@echo off
echo Copying notification sound to apps...
echo.

REM Create assets folders if they don't exist
if not exist "apps\admin_app\assets" mkdir "apps\admin_app\assets"
if not exist "apps\staff_app\assets" mkdir "apps\staff_app\assets"

REM Copy the sound file to both apps (rename to remove space)
copy "notification sound.mp3" "apps\admin_app\assets\notification_sound.mp3"
copy "notification sound.mp3" "apps\staff_app\assets\notification_sound.mp3"

echo.
echo Done! The notification sound has been copied to:
echo   - apps\admin_app\assets\notification_sound.mp3
echo   - apps\staff_app\assets\notification_sound.mp3
echo.
echo Now run: flutter pub get (in each app folder)
echo.
pause


