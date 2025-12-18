# Import Fix Status

## ✅ Completed

1. **Router Fixed** - `apps/admin_app/lib/core/router/admin_router.dart`
   - Fixed `UserDetailScreen` to load user from provider
   - Fixed `UserOnboardingViewScreen` to load user from provider  
   - Fixed `AddEditProjectScreen` to use project parameter
   - Added Provider imports

2. **Shared Package Exports Updated** - `packages/shared/lib/shared.dart`
   - Added all model exports
   - Added most provider exports
   - Added service exports
   - Added utils exports

## ⚠️ Missing Providers (Need to Copy from mobile)

The following providers exist in `mobile/lib/core/providers/` but are NOT in `packages/shared/lib/core/providers/`:

- `timesheet_provider.dart` ⚠️
- `document_provider.dart` ⚠️
- `incident_provider.dart` ⚠️
- `location_provider.dart` ⚠️
- `xero_provider.dart` ⚠️

**Action Required:** Copy these files from `mobile/lib/core/providers/` to `packages/shared/lib/core/providers/`

## 📋 Remaining Import Fixes Needed

All files in `apps/admin_app/lib/features/` still have relative imports that need to be replaced:

**Pattern:**
```
OLD: import '../../../core/providers/auth_provider.dart';
NEW: import 'package:staff4dshire_shared/shared.dart';
```

## 🔧 Quick Fix Steps

### Step 1: Copy Missing Providers
```bash
# Copy missing providers to shared package
cp mobile/lib/core/providers/timesheet_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/document_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/incident_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/location_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/xero_provider.dart packages/shared/lib/core/providers/
```

### Step 2: Fix Imports in Admin App

**Option A: Use IDE Find & Replace (Recommended)**

In VS Code or Android Studio:
1. Open Find & Replace (Ctrl+Shift+H / Cmd+Shift+H)
2. Enable Regex mode
3. Find: `import\s+['"]\.\.\/\.\.\/\.\.\/core\/(providers|models|services|utils|config)\/[^'"]+['"];`
4. Replace: `import 'package:staff4dshire_shared/shared.dart';`
5. Scope: `apps/admin_app/lib`
6. Replace All

**Option B: Use PowerShell Script**

Run `FIX_ALL_IMPORTS.ps1` (but it needs refinement)

### Step 3: Remove Duplicate Imports

After replacing, each file should have only ONE line:
```dart
import 'package:staff4dshire_shared/shared.dart';
```

Remove any duplicates.

### Step 4: Run pub get

```bash
cd packages/shared
flutter pub get

cd ../../apps/admin_app
flutter pub get
```

### Step 5: Verify

```bash
cd apps/admin_app
flutter analyze
```

This should show significantly fewer errors (mainly just missing provider files).

## 📝 Files That Need Manual Attention

After automated fix, some files may still need manual tweaks:
- Files that import specific models that aren't exported
- Files with conditional imports
- Test files

## 🎯 Expected Outcome

After completing these steps:
- ✅ Router working
- ✅ All imports using shared package
- ✅ All providers available
- ⚠️ Some compile-time errors may remain for missing implementations



