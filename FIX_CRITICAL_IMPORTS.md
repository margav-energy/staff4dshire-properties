# Fix Critical Imports - Commands

## Step 1: Fix Login Screen Imports

In `apps/admin_app/lib/features/auth/screens/login_screen.dart`, change:
- `import '../../../core/providers/auth_provider.dart';` 
  → `import 'package:staff4dshire_shared/shared.dart';`
- `import '../../../core/providers/user_provider.dart';`
  → Remove (already in shared.dart)

## Step 2: Update Shared Package Exports

I've already updated `packages/shared/lib/shared.dart` to export the new providers.

## Step 3: Run pub get

```bash
cd packages/shared
flutter pub get

cd ../../apps/admin_app
flutter pub get
```

## Step 4: Test Build

```bash
cd apps/admin_app
flutter analyze
```

This will show all import errors that need fixing.

## Quick Fix Command (if you have sed/grep)

```bash
# Navigate to admin_app
cd apps/admin_app

# Find all files with old import pattern
find lib -name "*.dart" -type f | xargs grep -l "../../../core" | head -20
```

## Manual Fix Pattern

In each file, find and replace:
- `../../../core/providers/` → Use `package:staff4dshire_shared/shared.dart` instead
- `../../../core/models/` → Use `package:staff4dshire_shared/shared.dart` instead
- `../../../core/services/` → Use `package:staff4dshire_shared/shared.dart` instead
- `../../../core/config/` → Use `package:staff4dshire_shared/shared.dart` instead

Then remove duplicate imports and keep only the shared.dart import.

## Use IDE Find & Replace

Most IDEs support find/replace across files:
1. Find: `import '../../../core/providers/(.*)';`
2. Replace with: `import 'package:staff4dshire_shared/shared.dart';`
3. Do this for providers, models, services, config



