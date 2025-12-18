# Xero Integration Setup Guide

This guide will help you set up the Xero integration for Staff4dshire Properties.

## Overview

The Xero integration allows you to:
- Connect your Xero accounting account
- Sync approved timesheets to Xero invoices
- View and manage Xero contacts
- Track invoice creation and sync status

## Prerequisites

1. A Xero account (Business or Premium plan recommended)
2. Access to Xero Developer Portal (https://developer.xero.com)
3. Admin access to configure the app

## Step 1: Create a Xero App

1. Go to [Xero Developer Portal](https://developer.xero.com/myapps)
2. Click "New app" or "Add application"
3. Fill in the app details:
   - **App name**: Staff4dshire Properties
   - **Company or application URL**: Your app's URL
   - **Support email**: Your support email
   - **Redirect URI**: `staff4dshire://xero/callback`
4. Select the **OAuth 2.0 (PKCE)** authorization flow
5. Select the scopes you need:
   - `accounting.transactions` - Create and view invoices
   - `accounting.contacts` - View and manage contacts
   - `offline_access` - Refresh tokens for long-term access
6. Click "Create app"
7. Copy your **Client ID** (you'll need this)

## Step 2: Configure the App

1. Open `mobile/lib/core/providers/xero_provider.dart`
2. Find the `_clientId` constant:
   ```dart
   static const String _clientId = 'YOUR_XERO_CLIENT_ID';
   ```
3. Replace `YOUR_XERO_CLIENT_ID` with your actual Client ID from Step 1
4. Update the `_redirectUri` if needed:
   ```dart
   static const String _redirectUri = 'staff4dshire://xero/callback';
   ```
5. Save the file

## Step 3: Configure Deep Links (Mobile Apps)

### Android

1. Open `mobile/android/app/src/main/AndroidManifest.xml`
2. Add the intent filter to your main activity:
   ```xml
   <activity
       android:name=".MainActivity"
       ...>
       <!-- Existing intent filters -->
       
       <!-- Xero OAuth callback -->
       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data
               android:scheme="staff4dshire"
               android:host="xero"
               android:pathPrefix="/callback" />
       </intent-filter>
   </activity>
   ```

### iOS

1. Open `mobile/ios/Runner/Info.plist`
2. Add the URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>staff4dshire</string>
           </array>
       </dict>
   </array>
   ```

## Step 4: Set Up Database Schema

1. Run the Xero integration schema SQL:
   ```bash
   psql -d your_database_name -f backend/xero_integration_schema.sql
   ```

   Or manually execute the SQL from `backend/xero_integration_schema.sql`

## Step 5: Connect Xero in the App

1. Open the app and log in as an admin
2. Go to **Settings** → **Integrations**
3. Tap on **Xero Accounting**
4. Tap **Connect to Xero**
5. You'll be redirected to Xero's login page
6. Log in with your Xero credentials
7. Authorize the app to access your Xero account
8. You'll be redirected back to the app

## Step 6: Create Invoices from Timesheets

1. Ensure timesheet entries are approved (by supervisor)
2. Go to **Settings** → **Integrations** → **Xero Accounting**
3. Tap **Create Invoice from Timesheet**
4. Select a Xero contact
5. Review the invoice details
6. Tap **Create Invoice**
7. The invoice will be created in Xero

## API Reference

### Available Methods

- `connectXero()` - Initiates OAuth flow
- `disconnectXero()` - Disconnects Xero account
- `getContacts()` - Retrieves all Xero contacts
- `createInvoice()` - Creates an invoice in Xero
- `getInvoices()` - Retrieves invoices from Xero

## Troubleshooting

### "Client ID not configured" Error

- Make sure you've updated `_clientId` in `xero_provider.dart`
- Verify the Client ID is correct in Xero Developer Portal

### OAuth Callback Not Working

- Verify deep link configuration (Step 3)
- Check that the redirect URI matches in Xero app settings
- For web, ensure the redirect URI is properly configured

### Token Refresh Issues

- The app automatically refreshes tokens when they expire
- If refresh fails, disconnect and reconnect Xero
- Check that `offline_access` scope is enabled

### Invoice Creation Fails

- Ensure timesheet entries are approved
- Verify the selected contact exists in Xero
- Check Xero account permissions
- Review error messages in the app

## Security Notes

- Client ID can be stored in code (it's public)
- Access tokens are stored securely in SharedPreferences
- Tokens automatically expire and refresh
- Disconnect Xero if you suspect unauthorized access

## Next Steps

1. Configure project-to-contact mapping for automatic invoice routing
2. Set up default hourly rates for invoice line items
3. Automate invoice creation on timesheet approval
4. Set up payment tracking synchronization

## Support

For Xero API documentation:
- https://developer.xero.com/documentation

For app support, contact your development team.


