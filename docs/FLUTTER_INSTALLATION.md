# Flutter Installation Guide for Windows

## Step 1: Download Flutter SDK

1. Visit the Flutter website: https://flutter.dev/docs/get-started/install/windows
2. Download the latest stable Flutter SDK for Windows
3. Extract the zip file to a location like `C:\src\flutter`
   - **Important**: Do NOT install Flutter in a path with spaces (like `C:\Program Files\`)
   - Recommended: `C:\src\flutter` or `C:\flutter`

## Step 2: Update PATH Environment Variable

1. Press `Win + R` and type `sysdm.cpl`, then press Enter
2. Click the **Advanced** tab
3. Click **Environment Variables**
4. Under **User variables**, find `Path` and click **Edit**
5. Click **New** and add the path to Flutter:
   - Example: `C:\src\flutter\bin`
6. Click **OK** on all dialogs

## Step 3: Verify Installation (New Terminal)

**Important**: Close and reopen your terminal/Git Bash for PATH changes to take effect.

Then run:
```bash
flutter --version
```

You should see Flutter version information.

## Step 4: Run Flutter Doctor

```bash
flutter doctor
```

This will check your Flutter installation and identify any missing dependencies.

## Step 5: Install Missing Dependencies

### Install Android Studio (for Android development)
1. Download from: https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio and complete the setup wizard
4. Install Android SDK and tools through Android Studio

### Install VS Code (Optional but Recommended)
1. Download from: https://code.visualstudio.com/
2. Install the Flutter extension from VS Code marketplace

### Install Git (if not already installed)
- Download from: https://git-scm.com/download/win
- Flutter uses Git for dependency management

## Step 6: Accept Android Licenses

```bash
flutter doctor --android-licenses
```

Press `y` to accept all licenses.

## Step 7: Install Project Dependencies

Once Flutter is properly installed:

```bash
cd mobile
flutter pub get
```

## Common Issues

### Issue: "flutter: command not found"
**Solution**: 
- Make sure you added Flutter to your PATH
- Close and reopen your terminal
- Verify the path is correct: `echo $PATH` (Git Bash) or `echo %PATH%` (CMD)

### Issue: Git not found
**Solution**: Install Git and add it to PATH, or reinstall Git and select "Add to PATH" during installation

### Issue: Android toolchain issues
**Solution**: 
- Install Android Studio
- Run `flutter doctor` to see specific issues
- Follow the suggestions provided by `flutter doctor`

## Verify Everything Works

```bash
flutter doctor -v
```

All checkmarks (✓) should be green. Yellow warnings are usually okay for basic development.

## Quick Start After Installation

1. Navigate to mobile directory:
   ```bash
   cd mobile
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. List available devices:
   ```bash
   flutter devices
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Need Help?

- Flutter documentation: https://flutter.dev/docs
- Flutter troubleshooting: https://flutter.dev/docs/get-started/install/windows#troubleshooting
- Check `flutter doctor` output for specific guidance

