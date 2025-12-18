# Email Service Setup

## Overview
The invitation system sends emails to company admins when invitations are created. This requires configuring an SMTP email service.

## Required Environment Variables

Add these to your `.env` file in the `backend` directory:

```env
# Email Service Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@staff4dshire.com

# Application Base URL (for invitation links)
APP_BASE_URL=https://app.staff4dshire.com
# For development: APP_BASE_URL=http://localhost:3000
```

## Gmail Setup (Recommended for Development)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Generate a password for "Mail"
   - Use this password in `SMTP_PASSWORD`

3. **Update `.env` file**:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-email@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   SMTP_FROM=your-email@gmail.com
   ```

## Production Email Services

For production, consider using:
- **SendGrid** (recommended)
- **Mailgun**
- **Amazon SES**
- **Postmark**

### SendGrid Example
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_FROM=noreply@staff4dshire.com
```

### Mailgun Example
```env
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=postmaster@yourdomain.com
SMTP_PASSWORD=your-mailgun-password
SMTP_FROM=noreply@yourdomain.com
```

## Testing

1. Install dependencies:
   ```bash
   cd backend
   npm install nodemailer
   ```

2. Update `.env` with your email credentials

3. Restart the backend server

4. Create a company invitation - email should be sent automatically

## Troubleshooting

- **Email not sending**: Check server logs for SMTP errors
- **Authentication failed**: Verify SMTP credentials and app password (for Gmail)
- **Connection timeout**: Check firewall/network settings
- **Emails going to spam**: Configure SPF/DKIM records for your domain



