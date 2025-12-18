# Google Sign-In Setup Guide

## Overview
The app now supports user registration with:
- Email and Password
- Google Sign-In

## Configuration Required

### For Android:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials (Android)
5. Download the `google-services.json` file
6. Place it in `android/app/`
7. Update your package name in `android/app/build.gradle`

### For iOS:
1. In Google Cloud Console, create OAuth 2.0 credentials (iOS)
2. Download the `GoogleService-Info.plist` file
3. Place it in `ios/Runner/`
4. Update your bundle identifier

### For Web:
1. In Google Cloud Console, create OAuth 2.0 credentials (Web)
2. Add authorized JavaScript origins
3. Update the client ID in your code

## Current Implementation

The Google Sign-In is currently implemented using mock/demo mode. For production:
- Connect to your backend authentication service
- Store user tokens securely
- Implement proper error handling
- Add Firebase Authentication (recommended)

## Testing

For testing purposes, the app will:
- Accept any valid email/password for registration
- Allow Google Sign-In if configured
- Assign roles based on email patterns:
  - Contains "admin" → Admin role
  - Contains "supervisor" or "super" → Supervisor role
  - Otherwise → Staff role


