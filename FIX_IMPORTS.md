# Fix Import Paths - Run These Commands

After copying files, you need to fix import paths. Here are commands to help:

## Common Import Patterns to Fix

The copied files likely have imports like:
- `../../../core/` → Should use `package:staff4dshire_shared/shared.dart`
- `../../core/` → Should use `package:staff4dshire_shared/shared.dart`
- `../../../core/providers/auth_provider.dart` → Use shared package

## Files That Need Import Fixes

### 1. Login Screen
File: `apps/admin_app/lib/features/auth/screens/login_screen.dart`
- Fix imports for AuthProvider, UserProvider
- Fix imports for theme/widgets

### 2. Dashboard Screens
Files: 
- `apps/admin_app/lib/features/dashboard/screens/admin_dashboard_screen.dart`
- `apps/admin_app/lib/features/dashboard/screens/superadmin_dashboard_screen.dart`
- Fix imports for providers, models, widgets

### 3. User Management
Files in `apps/admin_app/lib/features/users/`
- Fix all relative imports

### 4. All Other Features
All files in `apps/admin_app/lib/features/*/` need import path fixes.

## Quick Fix Strategy

1. **For shared/core imports**: Replace with `package:staff4dshire_shared/shared.dart`
2. **For feature imports**: Keep relative paths but update depth
3. **For widget imports**: Keep relative paths within features

## Manual Fix Needed

Unfortunately, import fixes need to be done manually or with find/replace in your IDE. 

The pattern is:
- OLD: `import '../../../core/providers/auth_provider.dart';`
- NEW: `import 'package:staff4dshire_shared/shared.dart';` (then use AuthProvider directly)

Or keep specific imports if they're not exported:
- OLD: `import '../../../core/models/user_model.dart';`
- NEW: `import 'package:staff4dshire_shared/shared.dart';`

## Use Your IDE

Most IDEs (VS Code, Android Studio) can help:
1. Right-click on error
2. Select "Quick Fix" or "Import"
3. Choose the correct import from shared package



