# Running the Admin App

## If Chrome Launch Fails

Try these alternatives:

### Option 1: Use web-server (Recommended)
```bash
flutter run -d web-server
```
Then manually open the URL shown in the terminal (usually http://localhost:port)

### Option 2: Use Edge
```bash
flutter run -d edge
```

### Option 3: Use Windows Desktop
```bash
flutter run -d windows
```

### Option 4: Build and serve manually
```bash
flutter build web
# Then serve the build/web directory with any web server
# Or use Python: python -m http.server 8000 -d build/web
```

## Quick Fix

The easiest solution is:
```bash
flutter run -d web-server
```

Then copy the URL (like `http://localhost:61370`) and paste it in any browser.



