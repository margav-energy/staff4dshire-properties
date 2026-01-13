# Setup Notification Sound

## Steps to Complete Setup

### 1. Copy the Sound File

You need to manually copy the notification sound file to both apps:

**For Admin App:**
```bash
# Create assets folder if it doesn't exist
mkdir apps\admin_app\assets

# Copy the sound file
copy "notification sound.mp3" apps\admin_app\assets\notification_sound.mp3
```

**For Staff App:**
```bash
# Create assets folder if it doesn't exist
mkdir apps\staff_app\assets

# Copy the sound file
copy "notification sound.mp3" apps\staff_app\assets\notification_sound.mp3
```

### 2. Install Dependencies

After copying the files, run:

**For Admin App:**
```bash
cd apps/admin_app
flutter pub get
```

**For Staff App:**
```bash
cd apps/staff_app
flutter pub get
```

**For Shared Package:**
```bash
cd packages/shared
flutter pub get
```

### 3. Restart Your Apps

Hot restart or rebuild your Flutter apps to see the changes:

```bash
# In your Flutter app terminal, press 'R' for hot restart
# Or stop and restart:
flutter run
```

## What Was Changed

✅ Added `audioplayers: ^5.2.1` dependency to:
- `apps/admin_app/pubspec.yaml`
- `apps/staff_app/pubspec.yaml`
- `packages/shared/pubspec.yaml`

✅ Added assets section to pubspec files:
- Both apps now include `assets/notification_sound.mp3` in their asset manifests

✅ Updated notification sound playback:
- `ChatProvider` now uses `audioplayers` to play the sound
- `NotificationProvider` now uses `audioplayers` to play the sound
- Sound plays on all platforms (web, mobile, desktop)

## Testing

After setup, you should hear the notification sound when:
1. You receive a new chat message
2. You receive a new notification (project assignment, etc.)

## Troubleshooting

If the sound doesn't play:
1. Make sure the file was copied correctly (check `apps/admin_app/assets/notification_sound.mp3` exists)
2. Run `flutter pub get` in all three locations (admin app, staff app, shared package)
3. Hot restart your app (press 'R' in Flutter terminal)
4. Check the console for any error messages about audio playback


