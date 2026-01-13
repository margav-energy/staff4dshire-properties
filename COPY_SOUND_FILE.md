# Copy Notification Sound File

## Quick Method (Windows)

**Double-click `COPY_SOUND_FILE.bat`** in the root folder - it will automatically:
1. Create the `assets` folders in both apps
2. Copy the sound file to both locations
3. Rename it to `notification_sound.mp3` (removes the space)

## Manual Method (Windows)

1. **Create the assets folders:**
   ```cmd
   mkdir apps\admin_app\assets
   mkdir apps\staff_app\assets
   ```

2. **Copy the sound file:**
   ```cmd
   copy "notification sound.mp3" apps\admin_app\assets\notification_sound.mp3
   copy "notification sound.mp3" apps\staff_app\assets\notification_sound.mp3
   ```

## After Copying

Run these commands to install dependencies:

```bash
cd packages/shared
flutter pub get

cd ../../apps/admin_app
flutter pub get

cd ../staff_app
flutter pub get
```

Then restart your apps!


