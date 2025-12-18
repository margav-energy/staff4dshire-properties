# Step-by-Step Guide: Fix Imports

## Step 1: Copy Missing Providers ✅

### Option A: Using Terminal (Windows Git Bash)
```bash
cp mobile/lib/core/providers/timesheet_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/document_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/incident_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/location_provider.dart packages/shared/lib/core/providers/
cp mobile/lib/core/providers/xero_provider.dart packages/shared/lib/core/providers/
```

### Option B: Using File Explorer
1. Open `mobile/lib/core/providers/` folder
2. Copy these 5 files:
   - `timesheet_provider.dart`
   - `document_provider.dart`
   - `incident_provider.dart`
   - `location_provider.dart`
   - `xero_provider.dart`
3. Paste them into `packages/shared/lib/core/providers/`

### Option C: Using PowerShell
```powershell
Copy-Item "mobile\lib\core\providers\timesheet_provider.dart" "packages\shared\lib\core\providers\"
Copy-Item "mobile\lib\core\providers\document_provider.dart" "packages\shared\lib\core\providers\"
Copy-Item "mobile\lib\core\providers\incident_provider.dart" "packages\shared\lib\core\providers\"
Copy-Item "mobile\lib\core\providers\location_provider.dart" "packages\shared\lib\core\providers\"
Copy-Item "mobile\lib\core\providers\xero_provider.dart" "packages\shared\lib\core\providers\"
```

---

## Step 2: Fix Imports in Admin App

### Option A: Automated PowerShell Script (Easiest) ⭐

1. Open PowerShell in the project root
2. Run:
```powershell
powershell -ExecutionPolicy Bypass -File fix_imports_simple.ps1
```

This will automatically fix all imports!

### Option B: VS Code Find & Replace (Manual but Reliable)

1. **Open VS Code** in the project folder
2. **Open Find & Replace:**
   - Press `Ctrl+Shift+H` (Windows/Linux) or `Cmd+Shift+H` (Mac)
   - Or click the search icon in sidebar → "Replace in Files"
3. **Enable Regex:**
   - Click the `.*` button to enable regex mode
4. **Find:** (paste this exactly)
   ```
   import\s+['"]\.\.\/\.\.\/\.\.\/core\/(providers|models|services|utils|config)\/[^'"]+['"];
   ```
5. **Replace with:** (paste this)
   ```
   import 'package:staff4dshire_shared/shared.dart';
   ```
6. **Files to include:** 
   ```
   apps/admin_app/lib/**/*.dart
   ```
7. **Click "Replace All"**
8. **Clean up duplicates:**
   - Some files may now have multiple `import 'package:staff4dshire_shared/shared.dart';` lines
   - Remove duplicates, keeping only one

### Option C: Android Studio

1. **Open Find & Replace:**
   - Press `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
2. **Enable Regex:**
   - Check the "Regex" checkbox
3. **Find:**
   ```
   import\s+['"]\.\.\/\.\.\/\.\.\/core\/(providers|models|services|utils|config)\/[^'"]+['"];
   ```
4. **Replace:**
   ```
   import 'package:staff4dshire_shared/shared.dart';
   ```
5. **Scope:** Select "Directory" → Choose `apps/admin_app/lib`
6. **Click "Find" then "Replace All"**

---

## Step 3: Update Shared Package Exports

I've already done this! The file `packages/shared/lib/shared.dart` is updated.

But let's verify by running:
```bash
cd packages/shared
flutter pub get
```

---

## Step 4: Test

```bash
cd apps/admin_app
flutter pub get
flutter analyze
```

You should see much fewer errors!

---

## Quick Summary

**Easiest Method:**
1. Copy the 5 provider files (manually or with commands above)
2. Run: `powershell -ExecutionPolicy Bypass -File fix_imports_simple.ps1`
3. Run: `cd packages/shared && flutter pub get`
4. Run: `cd ../../apps/admin_app && flutter pub get`
5. Run: `flutter analyze`

That's it! 🎉



