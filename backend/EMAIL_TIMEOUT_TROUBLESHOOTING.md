# Email Connection Timeout Troubleshooting

## Problem
You're seeing this error:
```
⚠️  Email service configuration error (emails will not be sent): Connection timeout
```

## Common Causes & Solutions

### 1. Gmail Blocking Render IPs
Gmail may block connections from cloud hosting providers like Render. This is a common issue.

**Solution Options:**

#### Option A: Use "Less Secure App Access" (Not Recommended)
- Not available for Gmail anymore (deprecated)
- Use App Passwords instead (which you're already doing)

#### Option B: Use a Professional Email Service (Recommended)
Switch to a service designed for transactional emails:

**SendGrid (Free tier: 100 emails/day)**
```
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_FROM=noreply@staff4dshire.com
```

**Mailgun (Free tier: 5,000 emails/month)**
```
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=postmaster@yourdomain.com
SMTP_PASSWORD=your-mailgun-password
SMTP_FROM=noreply@yourdomain.com
```

**Amazon SES (Very cheap, pay per email)**
```
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=your-ses-smtp-username
SMTP_PASSWORD=your-ses-smtp-password
SMTP_FROM=noreply@yourdomain.com
```

### 2. Check Environment Variables
Verify all SMTP variables are set correctly in Render:
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_FROM`

### 3. Verify Gmail App Password
- Make sure you're using an **App Password**, not your regular Gmail password
- App passwords are 16 characters (remove spaces when pasting)
- Regenerate the app password if it's not working

### 4. Network/Firewall Issues
- Render's network might be blocked by Gmail
- Try using a different SMTP port (465 with `secure: true` instead of 587)

### 5. Test Connection
After updating settings, check the logs. You should see:
```
✅ Email service is ready to send messages
```

If you still see timeout errors, switch to SendGrid or Mailgun - they're designed for this use case.

## Quick Fix: Switch to SendGrid

1. Sign up at https://sendgrid.com (free tier available)
2. Create an API key in Settings → API Keys
3. Update Render environment variables:
   ```
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USER=apikey
   SMTP_PASSWORD=your-sendgrid-api-key-here
   SMTP_FROM=ella@margav.energy
   ```
4. Redeploy - emails should work immediately

SendGrid is much more reliable than Gmail for transactional emails from cloud servers.
