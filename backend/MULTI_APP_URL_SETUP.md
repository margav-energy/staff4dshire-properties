# Multi-App URL Configuration

## Overview
You have two apps (admin_app and staff_app), and invitations need to point to the correct app based on the user's role.

## Environment Variables for Render

Add these environment variables in your Render dashboard:

### Required (Email Service)
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=ella@margav.energy
SMTP_PASSWORD=ljevsysujbxhaqxw
SMTP_FROM=ella@margav.energy
```

### App URLs (Choose one option)

#### Option 1: Separate URLs for Each App (Recommended)
```
ADMIN_APP_BASE_URL=https://your-admin-app.onrender.com
STAFF_APP_BASE_URL=https://your-staff-app.onrender.com
APP_BASE_URL=https://your-admin-app.onrender.com  # Fallback
```

#### Option 2: Single URL (If both apps share same domain)
```
APP_BASE_URL=https://your-app.onrender.com
```

## How It Works

### Invitation Requests (Creates Admin Accounts)
- Uses: `ADMIN_APP_BASE_URL` → `APP_BASE_URL` → `http://localhost:3000`
- These always create admin accounts, so they go to the admin app

### Company Invitations
- **Admin role**: Uses `ADMIN_APP_BASE_URL` → `APP_BASE_URL` → `http://localhost:3000`
- **Supervisor/Staff role**: Uses `STAFF_APP_BASE_URL` → `APP_BASE_URL` → `http://localhost:3000`
- Automatically routes to the correct app based on the invitation role

## Example Setup

If your apps are deployed at:
- Admin App: `https://staff4dshire-admin.onrender.com`
- Staff App: `https://staff4dshire-staff.onrender.com`

Set in Render:
```
ADMIN_APP_BASE_URL=https://staff4dshire-admin.onrender.com
STAFF_APP_BASE_URL=https://staff4dshire-staff.onrender.com
APP_BASE_URL=https://staff4dshire-admin.onrender.com
```

## Override Per Request

The frontend can also pass `base_url` in the request body to override the environment variable for a specific request.

## Notes

- If you only set `APP_BASE_URL`, all invitations will use that URL
- `ADMIN_APP_BASE_URL` and `STAFF_APP_BASE_URL` take precedence when set
- The fallback order ensures invitations always work even if some URLs aren't set
