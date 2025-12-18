# Quick Start Guide - Staff4dshire Properties

## Prerequisites Check

Before you begin, ensure you have:

- [ ] **Flutter SDK** installed (see `docs/FLUTTER_INSTALLATION.md`)
- [ ] **Node.js 18+** installed (for web app)
- [ ] **PostgreSQL** installed (for database)
- [ ] **Git** installed (recommended)

## Installation Steps

### 1. Install Flutter (If Not Already Installed)

**Windows:**
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter` (or similar path without spaces)
3. Add `C:\src\flutter\bin` to your PATH environment variable
4. **Close and reopen your terminal**
5. Verify: `flutter --version`
6. Run: `flutter doctor` to check installation

See `docs/FLUTTER_INSTALLATION.md` for detailed instructions.

### 2. Setup Mobile App

```bash
cd mobile
flutter pub get
```

**Note**: If you get "flutter: command not found", Flutter is not in your PATH. See installation guide above.

### 3. Setup Web App

```bash
cd web
npm install
```

### 4. Setup Database

```bash
# Create database
createdb staff4dshire

# Run schema
psql -d staff4dshire -f backend/schema.sql
```

## Running the Applications

### Mobile App (Flutter)

```bash
cd mobile

# Check connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Run in Chrome (for web testing)
flutter run -d chrome
```

### Web App (Next.js)

```bash
cd web

# Development mode
npm run dev

# Open browser to http://localhost:3000
```

## Testing the Setup

### Mobile App
1. Run `flutter doctor` - should show no critical errors
2. Run `flutter devices` - should list available devices
3. Run `flutter run` - app should launch

### Web App
1. Run `npm run dev`
2. Open http://localhost:3000
3. You should see the login page

## Project Structure

```
Staff4dshire Properties/
├── mobile/           # Flutter mobile app
├── web/              # Next.js web app
├── backend/          # Database schema
├── docs/             # Documentation
└── README.md
```

## Next Steps

1. **Configure API endpoints** - Update API URLs in both apps
2. **Add assets** - Add logos, images to `mobile/assets/`
3. **Set up authentication** - Connect to your backend API
4. **Configure database** - Update connection strings

## Getting Help

- **Flutter issues**: See `docs/FLUTTER_INSTALLATION.md`
- **Setup issues**: See `docs/SETUP.md`
- **Feature docs**: See `docs/FEATURES.md`
- **Design system**: See `docs/DESIGN_SYSTEM.md`

