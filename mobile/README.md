# Staff4dshire Properties - Mobile App

Flutter mobile application for staff and subcontractor management.

## Flutter Installation Path

Flutter is installed at: `C:\Users\develop\flutter`

## Quick Start

### Using Command Prompt (CMD) - Recommended

```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
flutter pub get
flutter run
```

### Using Git Bash

First, add Flutter to your PATH (run once):
```bash
echo 'export PATH="$PATH:/c/Users/develop/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

Then:
```bash
cd mobile
flutter pub get
flutter run
```

### Using PowerShell

```powershell
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
& "C:\Users\develop\flutter\bin\flutter.exe" pub get
flutter run
```

## Installation Scripts

- `install.bat` - For CMD (double-click or run from CMD)
- `install.sh` - For Git Bash (bash install.sh)
- `install.ps1` - For PowerShell (.\install.ps1)

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/                     # Core functionality
│   │   ├── theme/                # App theme and colors
│   │   ├── router/               # Navigation routing
│   │   ├── providers/            # State management
│   │   └── models/               # Data models
│   └── features/                 # Feature modules
│       ├── auth/                 # Authentication
│       ├── dashboard/            # Dashboards (staff/supervisor/admin)
│       ├── timesheet/            # Timesheet management
│       ├── documents/            # Document hub
│       ├── compliance/           # Compliance features
│       └── projects/             # Project selection
├── assets/                       # Images, icons, fonts
└── pubspec.yaml                  # Dependencies

```

## Available Commands

```bash
flutter pub get          # Install dependencies
flutter doctor           # Check Flutter setup
flutter devices          # List available devices
flutter run              # Run the app
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
flutter test             # Run tests
```

## Features

- ✅ Sign in/out with GPS tracking
- ✅ Project selection
- ✅ Automatic timesheet generation
- ✅ Document hub with expiry tracking
- ✅ Compliance declarations (Fit-to-Work, RAMS, Toolbox Talks)
- ✅ Role-based dashboards (Staff, Supervisor, Admin)

## Troubleshooting

See `../INSTALL_INSTRUCTIONS.md` for detailed troubleshooting guide.

