# Map Location Picker Setup Guide

The map location picker requires the `google_maps_flutter` package to be installed and configured.

## Current Status

Right now, the app uses a **coordinate input fallback** that allows users to:
- Enter coordinates manually (latitude/longitude)
- Use current GPS location
- Lookup address from coordinates

This works immediately without any additional setup.

## To Enable Google Maps Interface

### Step 1: Install Dependencies

Run the following command in the `mobile` directory:

```bash
cd mobile
flutter pub get
```

### Step 2: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API (for web)
4. Go to "Credentials" and create an API key
5. Restrict the API key to your app's bundle ID/package name

### Step 3: Configure for Android

1. Open `mobile/android/app/src/main/AndroidManifest.xml`
2. Add the API key inside the `<application>` tag:

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

### Step 4: Configure for iOS

1. Open `mobile/ios/Runner/AppDelegate.swift`
2. Add the API key in the `application(_:didFinishLaunchingWithOptions:)` method:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### Step 5: Configure for Web

1. Create or edit `mobile/web/index.html`
2. Add the Maps JavaScript API script:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

### Step 6: Update the Map Location Picker

Once the package is installed, uncomment and update the Google Maps implementation in:
- `mobile/lib/features/auth/widgets/map_location_picker.dart`

Replace the fallback coordinate picker with the full Google Maps implementation.

## Alternative: Using the Coordinate Picker

If you prefer not to set up Google Maps, the coordinate picker works perfectly and provides:
- Manual coordinate input with validation
- Current location via GPS
- Address lookup from coordinates
- All the same functionality without requiring an API key

The coordinate picker is already active and working!

