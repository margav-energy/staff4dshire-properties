# Monorepo Setup Guide

## Structure

```
Staff4dshire Properties/
├── packages/
│   └── shared/              # Shared code package
│       ├── lib/
│       │   ├── core/        # Models, services, providers, utils
│       │   └── shared.dart  # Main export file
│       └── pubspec.yaml
├── apps/
│   ├── admin_app/           # Admin Portal app
│   │   ├── lib/
│   │   │   ├── features/    # Admin-specific features
│   │   │   ├── main.dart
│   │   │   └── router.dart
│   │   └── pubspec.yaml
│   └── staff_app/           # Staff App
│       ├── lib/
│       │   ├── features/    # Staff-specific features
│       │   ├── main.dart
│       │   └── router.dart
│       └── pubspec.yaml
└── backend/                 # Backend API (unchanged)
```

## Setup Instructions

### 1. Install Shared Package Dependencies

```bash
cd packages/shared
flutter pub get
```

### 2. Setup Admin App

```bash
cd apps/admin_app
flutter pub get
```

### 3. Setup Staff App

```bash
cd apps/staff_app
flutter pub get
```

## Running the Apps

### Admin App
```bash
cd apps/admin_app
flutter run
```

### Staff App
```bash
cd apps/staff_app
flutter run
```

## Building for Production

### Admin App
```bash
cd apps/admin_app
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

### Staff App
```bash
cd apps/staff_app
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

## Development Workflow

1. Make changes to shared code in `packages/shared/`
2. Both apps automatically use the updated shared code
3. Test both apps independently
4. Deploy separately when ready

## Next Steps

1. ✅ Create directory structure
2. ✅ Create shared package
3. ✅ Create admin_app and staff_app skeletons
4. ⏳ Move admin-specific features to admin_app
5. ⏳ Move staff-specific features to staff_app
6. ⏳ Create separate routers for each app
7. ⏳ Test both apps build and run



