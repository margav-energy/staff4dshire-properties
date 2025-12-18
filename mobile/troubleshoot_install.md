# Troubleshooting Flutter pub get

## Issue: Installation Taking Too Long (1+ hour)

This is NOT normal - `flutter pub get` should complete in 2-5 minutes at most.

## Quick Fixes

### 1. Cancel Current Process
If the script is still running:
- Press `Ctrl+C` in the terminal
- If that doesn't work, close the terminal window

### 2. Check Internet Connection
- Make sure you have a stable internet connection
- Try accessing https://pub.dev in your browser

### 3. Try Manual Install in CMD

Open a **NEW** Command Prompt window and run:

```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
flutter pub get --verbose
```

The `--verbose` flag will show detailed progress.

### 4. Check for Proxy/Firewall Issues

If you're behind a corporate firewall:
```cmd
flutter pub get --no-sound-null-safety
```

Or set HTTP proxy:
```cmd
set HTTP_PROXY=your-proxy:port
set HTTPS_PROXY=your-proxy:port
flutter pub get
```

### 5. Clear Flutter Cache

```cmd
flutter clean
flutter pub cache repair
flutter pub get
```

### 6. Try Installing One Package at a Time

Check `pubspec.yaml` - we have many packages. You can temporarily comment out some to test.

### 7. Check Flutter Doctor

```cmd
flutter doctor -v
```

This shows if there are any Flutter setup issues.

## Common Causes

1. **Network issues** - Slow or unstable connection
2. **Firewall blocking** - Corporate/antivirus firewall
3. **Disk space** - Not enough space for packages
4. **Permission issues** - Can't write to cache directory
5. **Stuck on specific package** - One package might be problematic

## Alternative: Install Minimal Dependencies

If full install fails, we can create a minimal `pubspec.yaml` with just essential packages to test.

