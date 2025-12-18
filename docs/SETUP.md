# Setup Guide - Staff4dshire Properties

## Prerequisites

### Mobile App (Flutter)
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDE)

### Web App (Next.js)
- Node.js 18.0.0 or higher
- npm or yarn package manager

### Backend
- PostgreSQL 14.0 or higher
- PostgreSQL client tools

## Mobile App Setup

### 1. Install Flutter
Follow the official Flutter installation guide: https://flutter.dev/docs/get-started/install

### 2. Clone and Setup
```bash
cd mobile
flutter pub get
```

### 3. Configure Assets
Ensure you have the following asset folders:
- `assets/images/`
- `assets/icons/`
- `assets/logos/`
- `assets/fonts/` (Inter font family)

### 4. Run the App
```bash
flutter run
```

### 5. Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Web App Setup

### 1. Install Dependencies
```bash
cd web
npm install
```

### 2. Environment Variables
Create a `.env.local` file:
```env
NEXT_PUBLIC_API_URL=http://localhost:3001/api
DATABASE_URL=postgresql://user:password@localhost:5432/staff4dshire
```

### 3. Run Development Server
```bash
npm run dev
```

The app will be available at `http://localhost:3000`

### 4. Build for Production
```bash
npm run build
npm start
```

## Backend Setup

### 1. Install PostgreSQL
Follow the official PostgreSQL installation guide for your OS.

### 2. Create Database
```bash
createdb staff4dshire
```

### 3. Run Schema
```bash
psql -d staff4dshire -f backend/schema.sql
```

### 4. Configure Connection
Update your backend configuration with database credentials.

## Configuration

### Mobile App Configuration
Edit `mobile/lib/core/config/app_config.dart` (create if needed):
```dart
class AppConfig {
  static const String apiBaseUrl = 'https://api.staff4dshire.com';
  static const String appVersion = '1.0.0';
}
```

### Web App Configuration
Edit `web/next.config.js` for additional configuration.

## Development Workflow

### Mobile Development
1. Start Flutter app in debug mode
2. Use hot reload for quick iterations
3. Test on both Android and iOS
4. Run tests: `flutter test`

### Web Development
1. Start Next.js dev server
2. Use hot reload for quick iterations
3. Test responsive design on multiple screen sizes
4. Run linting: `npm run lint`

## Testing

### Mobile Tests
```bash
cd mobile
flutter test
```

### Web Tests
```bash
cd web
npm test
```

## Deployment

### Mobile App Deployment
- **Android**: Upload APK/AAB to Google Play Store
- **iOS**: Upload to App Store Connect via Xcode

### Web App Deployment
Recommended platforms:
- **Vercel** (easiest for Next.js)
- **Netlify**
- **AWS Amplify**
- Custom server with Node.js

### Database Deployment
- **AWS RDS**
- **Google Cloud SQL**
- **Azure Database**
- Self-hosted PostgreSQL

## Troubleshooting

### Flutter Issues
- Run `flutter doctor` to check setup
- Clear build cache: `flutter clean && flutter pub get`
- Check device connection: `flutter devices`

### Next.js Issues
- Clear `.next` folder: `rm -rf .next`
- Reinstall dependencies: `rm -rf node_modules && npm install`
- Check Node.js version: `node --version`

### Database Issues
- Check PostgreSQL is running
- Verify connection string
- Check firewall settings
- Review database logs

## Support

For issues or questions:
1. Check documentation in `/docs` folder
2. Review code comments
3. Check GitHub issues (if using version control)
4. Contact development team

