# Install Dependencies Now - Quick Guide

## ✅ Use Command Prompt (CMD) - This Works!

Since Flutter works in CMD, use **Command Prompt**:

### Step 1: Open Command Prompt
- Press `Win + R`
- Type `cmd`
- Press Enter

### Step 2: Navigate to Mobile Directory
```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
```

### Step 3: Install Dependencies
```cmd
flutter pub get
```

That's it! ✅

---

## Alternative: If Flutter is in PATH in CMD but not PowerShell

If you want to use PowerShell, you can:

### Option A: Add Flutter to PowerShell PATH permanently

1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click **Advanced** tab → **Environment Variables**
3. Under **User variables**, find **Path** and click **Edit**
4. Click **New** and add: `C:\Users\develop\flutter\bin`
5. Click **OK** on all dialogs
6. **Restart PowerShell**
7. Then run: `cd mobile` and `flutter pub get`

### Option B: Just use CMD (Easiest!)

Since Flutter already works in CMD, just use CMD for now:
```cmd
cd "C:\Users\User\Desktop\Staff4dshire Properties\mobile"
flutter pub get
```

---

## After Installation

Once `flutter pub get` completes, you can:

```cmd
flutter doctor        # Check setup
flutter devices       # See available devices
flutter run           # Run the app
```

