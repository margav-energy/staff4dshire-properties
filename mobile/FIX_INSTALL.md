# Fix: Flutter pub get Error

## The Problem

You ran `flutter pub get` from the wrong directory (`C:\Windows\System32`).

The error message says:
```
Expected to find project root in current working directory.
```

## The Solution

**You MUST run `flutter pub get` from inside the `mobile` directory!**

### Option 1: Double-click the Batch File (Easiest!)

1. Open File Explorer
2. Navigate to: `C:\Users\User\Desktop\Staff4dshire Properties\mobile`
3. **Double-click `RUN_FLUTTER_PUB_GET.cmd`**
4. It will automatically:
   - Change to the correct directory
   - Run `flutter pub get`
   - Show you the results

### Option 2: Use Command Prompt

1. Open **Command Prompt** (CMD)
2. Run these commands **one at a time**:

```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
flutter pub get
```

**Important:** You MUST run `cd` first to change to the mobile directory!

### Option 3: Navigate First, Then Run

In CMD:
```cmd
cd /d "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
flutter pub get
```

## Why This Happened

- Flutter needs to find `pubspec.yaml` file
- `pubspec.yaml` is located in the `mobile` folder
- When you run from `C:\Windows\System32`, Flutter can't find it

## After Successful Installation

Once `flutter pub get` completes successfully, you'll see:
```
Got dependencies!
```

Then you can:
```cmd
flutter doctor      # Check your setup (optional)
flutter devices     # See available devices
flutter run         # Run the app
```

## Quick Summary

✅ **Correct:** Run from `mobile` directory  
❌ **Wrong:** Run from `C:\Windows\System32` or any other directory

**Solution:** Double-click `RUN_FLUTTER_PUB_GET.cmd` in the mobile folder! 🎯

