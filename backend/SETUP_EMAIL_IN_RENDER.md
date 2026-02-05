# Setting Up Email Service in Render

## Problem
You're seeing this message in your logs:
```
ℹ️  Email service not configured (SMTP_USER/SMTP_PASSWORD not set)
```

This means invitation emails are not being sent. Users can still create accounts, but they won't receive their login credentials via email.

## Solution: Configure SMTP in Render

### Step 1: Get SMTP Credentials

You have several options:

#### Option A: Gmail (Easiest for Testing)
1. Enable 2-Factor Authentication on your Gmail account
2. Go to Google Account → Security → 2-Step Verification → App passwords
3. Generate an app password for "Mail"
4. Use these settings:
   - **SMTP_HOST**: `smtp.gmail.com`
   - **SMTP_PORT**: `587`
   - **SMTP_USER**: Your Gmail address
   - **SMTP_PASSWORD**: The 16-character app password you generated
   - **SMTP_FROM**: Your Gmail address (optional)

#### Option B: SendGrid (Recommended for Production)
1. Sign up at [SendGrid](https://sendgrid.com)
2. Create an API key
3. Use these settings:
   - **SMTP_HOST**: `smtp.sendgrid.net`
   - **SMTP_PORT**: `587`
   - **SMTP_USER**: `apikey`
   - **SMTP_PASSWORD**: Your SendGrid API key
   - **SMTP_FROM**: `noreply@staff4dshire.com` (or your verified domain)

#### Option C: Mailgun
1. Sign up at [Mailgun](https://www.mailgun.com)
2. Get your SMTP credentials from the dashboard
3. Use these settings:
   - **SMTP_HOST**: `smtp.mailgun.org`
   - **SMTP_PORT**: `587`
   - **SMTP_USER**: Your Mailgun SMTP username
   - **SMTP_PASSWORD**: Your Mailgun SMTP password
   - **SMTP_FROM**: Your verified sender address

### Step 2: Add Environment Variables in Render

1. Go to your Render dashboard
2. Navigate to your backend service (`staff4dshire-backend`)
3. Click on **Environment** in the left sidebar
4. Click **Add Environment Variable** for each of these:

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password-or-api-key
SMTP_FROM=your-email@gmail.com
APP_BASE_URL=https://your-frontend-url.com
```

### Step 3: Redeploy

After adding the environment variables:
1. Render will automatically redeploy your service
2. Check the logs - you should see:
   ```
   ✅ Email service is ready to send messages
   ```
   Instead of:
   ```
   ℹ️  Email service not configured
   ```

### Step 4: Test

1. Create a new invitation request
2. Check the email inbox of the recipient
3. They should receive an email with their login credentials

## Fallback: Credentials in API Response

If email is not configured, the API will return credentials in the response:

```json
{
  "success": true,
  "message": "Your account has been created successfully! Please save your credentials below.",
  "credentials": {
    "email": "user@example.com",
    "password": "generated-password",
    "warning": "Email service is not configured. Please save these credentials now - they will not be shown again!"
  }
}
```

**Important**: Make sure your frontend displays these credentials to the user if they're present in the response!

## Troubleshooting

### Email Still Not Sending
1. Check Render logs for SMTP errors
2. Verify environment variables are set correctly (no typos)
3. For Gmail: Make sure you're using an App Password, not your regular password
4. Check if your SMTP provider requires IP whitelisting (Render's IPs may need to be whitelisted)

### Gmail Authentication Failed
- Make sure 2FA is enabled
- Use an App Password, not your regular Gmail password
- App passwords are 16 characters with spaces (you can remove spaces when pasting)

### SendGrid Not Working
- Make sure you're using `apikey` as the SMTP_USER
- Verify your API key has "Mail Send" permissions
- Check that your sender email is verified in SendGrid

## Security Note

Never commit SMTP credentials to git. Always use environment variables in Render.
