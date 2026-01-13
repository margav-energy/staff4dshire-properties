# How to See Chat Feature Changes

## Important: You Need to Restart Flutter Apps, Not Just the Backend!

The changes we made are in the **Flutter frontend code**, so you need to restart your Flutter apps.

## Steps to See Changes:

### Option 1: Hot Restart (Fastest)
If your Flutter apps are already running:

1. **In your Flutter terminal/console**, press:
   - `R` (capital R) for Hot Restart, OR
   - `Ctrl+C` to stop, then run `flutter run` again

### Option 2: Full Restart (Recommended if hot restart doesn't work)

#### For Admin App:
```bash
cd apps/admin_app
flutter clean
flutter pub get
flutter run
```

#### For Staff App:
```bash
cd apps/staff_app
flutter clean
flutter pub get
flutter run
```

## What We Changed:

1. ✅ **Forward feature** - Long press a message, select "Forward"
2. ✅ **File preview** - Before sending files/images, you'll see a preview dialog
3. ✅ **Read receipts** - Single/double ticks showing message status
4. ✅ **Chat header** - Name and avatar now in AppBar (top), removed from messages
5. ✅ **Badge everywhere** - Unread count badge shows on chat icon in bottom nav

## If Changes Still Don't Show:

1. **Clear browser cache** (if running on web):
   - Press `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)

2. **Check for compilation errors**:
   - Look for red error messages in your terminal
   - Fix any errors before restarting

3. **Ensure backend is running**:
   - The backend server should be running on port 3001
   - Check: `cd backend && node server.js`

4. **Verify you're looking at the right features**:
   - Try long-pressing a message to see Forward option
   - Try attaching a file to see the preview dialog
   - Check if your sent messages show ticks (read receipts)

## Quick Test:

1. Open a chat conversation
2. Long press on a message - you should see "Edit", "Forward", "Delete" options
3. Click attach icon → pick an image - you should see a preview dialog
4. Send a message - check for ticks at the bottom right of your message bubbles


