# Quick Fix Commands

## Option 1: Use PowerShell Script (Easiest)

```powershell
cd "C:\Users\User\Desktop\Staff4dshire Properties"
powershell -ExecutionPolicy Bypass -File FIX_ALL_IMPORTS.ps1
```

This will automatically fix most import paths.

## Option 2: Manual Fix - Critical Files First

Run these commands one at a time to check and fix critical files:

### 1. Update Shared Package
```bash
cd packages/shared
flutter pub get
```

### 2. Fix Login Screen (already done, but verify)
The login screen imports have been fixed. 

### 3. Fix Welcome Dialog
In `apps/admin_app/lib/features/auth/widgets/welcome_dialog.dart`, change:
- `import '../../../core/providers/auth_provider.dart';`
- To: `import 'package:staff4dshire_shared/shared.dart';`

### 4. Check for Errors
```bash
cd apps/admin_app
flutter analyze 2>&1 | Select-String "error" | Select-Object -First 20
```

This will show the files with import errors.

## Option 3: Use IDE Find & Replace

In VS Code or Android Studio:
1. Open Find & Replace (Ctrl+Shift+H)
2. Enable regex mode
3. Find: `import\s+['"]\.\.\/\.\.\/\.\.\/core\/(providers|models|services|config)\/[^'"]+['"];`
4. Replace: (leave empty to remove, then add shared.dart import manually)

## After Fixing Imports

1. Run `flutter pub get` in both shared and admin_app
2. Run `flutter analyze` to check for errors
3. Try building: `flutter build web` or `flutter run -d web-server`



