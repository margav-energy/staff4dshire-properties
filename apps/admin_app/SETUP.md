# Admin App Setup Instructions

## 1. Generate Platform Support

Run this command in the `apps/admin_app` directory:

```bash
flutter create . --platforms=web,windows,android,ios
```

**Note:** When prompted to overwrite files, choose:
- "N" (No) for `pubspec.yaml` - we need to keep our shared package dependency
- "Y" (Yes) for platform directories (web, windows, android, ios)

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Run the App

```bash
# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Android
flutter run -d android
```

## Troubleshooting

If you get errors about missing files, try:
```bash
flutter clean
flutter pub get
flutter create . --platforms=web
```



