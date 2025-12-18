# Fix Chrome Launch Issue

## Problem
Flutter can't launch Chrome automatically. This is a common issue.

## Solutions

### Solution 1: Use Web Server Mode (Recommended)

Instead of launching Chrome automatically, Flutter will start a web server and give you a URL to open manually:

```cmd
flutter run -d web-server
```

**Or double-click:** `RUN_WEB_SERVER.cmd`

When it starts, you'll see:
```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
...
The Flutter DevTools debugger and profiler on Windows is available at:
http://localhost:XXXXX
```

Then manually open Chrome and go to: `http://localhost:XXXXX`

### Solution 2: Try Edge Instead

If you have Microsoft Edge installed:

```cmd
flutter run -d edge
```

### Solution 3: Check Chrome Installation

Make sure Chrome is properly installed and accessible:
1. Open Chrome manually to verify it works
2. Try running: `chrome --version` in CMD
3. Make sure Chrome is at: `C:\Program Files\Google\Chrome\Application\chrome.exe`

### Solution 4: Manual Chrome Launch

1. Start Flutter in web-server mode:
   ```cmd
   flutter run -d web-server
   ```

2. Wait for the URL to appear (like `http://localhost:61261`)

3. Open Chrome manually and navigate to that URL

## Quick Fix (Try This First)

**Run this command:**
```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
flutter run -d web-server
```

When it shows the URL, copy it and paste it into Chrome manually.

---

**Recommended:** Use `-d web-server` mode - it's more reliable and you have full control over the browser!

