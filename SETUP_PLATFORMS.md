# Setting Up Platform Support for Apps

## Quick Setup

You need to generate platform support files for both apps. Run these commands:

### For Admin App
```bash
cd apps/admin_app
flutter create . --platforms=web,windows,android,ios
flutter pub get
```

### For Staff App
```bash
cd apps/staff_app
flutter create . --platforms=web,windows,android,ios
flutter pub get
```

## What This Does

The `flutter create .` command will:
- Create `web/` directory with web support
- Create `windows/` directory with Windows desktop support
- Create `android/` directory with Android support
- Create `ios/` directory with iOS support (if on Mac)
- Update `pubspec.yaml` if needed
- Generate necessary platform-specific files

## After Setup

Once platform files are generated, you can run:

```bash
# Run on web
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Run on Android emulator
flutter run -d android

# Run on iOS simulator (Mac only)
flutter run -d ios
```

## Note

- The command may ask to overwrite existing files - you can say "N" (no) if you've customized anything
- If prompted about existing `pubspec.yaml`, choose to keep your existing one (it has the shared package dependency)

## Alternative: Just Web Support

If you only need web support for now:

```bash
cd apps/admin_app
flutter create . --platforms=web
cd ../staff_app
flutter create . --platforms=web
```



