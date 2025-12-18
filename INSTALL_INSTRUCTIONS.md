# Installation Instructions

## Your Flutter Installation

Flutter is installed at: `C:\Users\develop\flutter`

## Quick Install - Use Command Prompt (CMD)

Since Flutter works in CMD, use **Command Prompt** to install dependencies:

1. Open **Command Prompt** (Win + R, type `cmd`, press Enter)
2. Navigate to the mobile directory:
   ```cmd
   cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
   ```
3. Install dependencies:
   ```cmd
   flutter pub get
   ```

**Or use the full path:**
```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
"C:\Users\develop\flutter\bin\flutter.exe" pub get
```

## Using Git Bash

### Option 1: Add to PATH (Recommended)

Run the setup script:
```bash
bash setup_flutter_path.sh
source ~/.bashrc
```

Or manually add to `~/.bashrc`:
```bash
echo 'export PATH="$PATH:/c/Users/develop/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

Then use normally:
```bash
cd mobile
flutter pub get
```

### Option 2: Use install script with full path

```bash
cd mobile
bash install.sh
```

## Using PowerShell

### Option 1: Use install script

```powershell
cd mobile
.\install.ps1
```

### Option 2: Use full path

```powershell
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
& "C:\Users\develop\flutter\bin\flutter.exe" pub get
```

## Verify Installation

After running `flutter pub get`, verify everything works:

```cmd
cd mobile
flutter doctor
flutter devices
```

## Running the App

Once dependencies are installed:

```cmd
cd mobile
flutter run
```

This will launch the app on a connected device or emulator.

## Troubleshooting

### If "flutter: command not found" in Git Bash/PowerShell:

1. **For Git Bash**: Run `bash setup_flutter_path.sh` and restart Git Bash
2. **For PowerShell**: Add Flutter to your PATH environment variable:
   - Go to System Properties → Environment Variables
   - Add `C:\Users\develop\flutter\bin` to User PATH
   - Restart PowerShell

### If Flutter path doesn't exist:

Verify your Flutter installation path:
```cmd
dir "C:\Users\develop\flutter\bin\flutter.exe"
```

If it doesn't exist, update the path in the scripts or use CMD where Flutter is already working.

## Quick Reference

**CMD (Recommended):**
```cmd
cd mobile
flutter pub get
```

**Git Bash:**
```bash
cd mobile
/c/Users/develop/flutter/bin/flutter pub get
```

**PowerShell:**
```powershell
cd mobile
& "C:\Users\develop\flutter\bin\flutter.exe" pub get
```
