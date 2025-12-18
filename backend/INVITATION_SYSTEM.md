# Company Invitation System

## Overview
When a superadmin creates a new company, they can invite an admin user to complete their registration. The invitation is sent via email automatically.

## How It Works

1. **Superadmin creates company** with admin email address
2. **System generates invitation** with unique token
3. **Email is sent automatically** to the admin email with:
   - Invitation link (click to register)
   - Invitation code (manual entry option)
   - Company name and role
   - Expiration date
4. **Admin receives email** and clicks the link or uses the code
5. **Admin completes registration** with name and password
6. **Account is created** and automatically assigned to the company

## Email Configuration

### Required Environment Variables (in `backend/.env`):

```env
# SMTP Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@staff4dshire.com

# App Base URL (for invitation links)
APP_BASE_URL=https://app.staff4dshire.com
# For development: APP_BASE_URL=http://localhost:3000
```

### Setting Up Gmail (Development)

1. Enable 2-Factor Authentication on your Gmail account
2. Generate an App Password:
   - Go to Google Account → Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
   - Use this 16-character password in `SMTP_PASSWORD`

### Production Email Services

For production, use a professional email service:
- **SendGrid** (recommended) - Free tier available
- **Mailgun** - Reliable and scalable
- **Amazon SES** - Cost-effective for high volume
- **Postmark** - Great deliverability

See `EMAIL_SETUP.md` for detailed configuration instructions.

## Important Notes

### Base URL Configuration

The `APP_BASE_URL` environment variable is **critical** for invitation links:

- **Development**: `http://localhost:3000` (for local testing)
- **Production**: `https://app.staff4dshire.com` (your deployed app URL)

**When deploying to production:**
1. Update `APP_BASE_URL` in `.env` to your production URL
2. Ensure the production URL is accessible from anywhere
3. The invitation link will use this URL so admins can register from anywhere in the world

### QR Code Limitation

The QR code in the invitation dialog is mainly for:
- **Local testing**: Scanning from another device on the same network
- **Demo purposes**: Showing the invitation visually
- **Manual sharing**: If email fails, you can share the QR code manually

**For production**, the email is the primary delivery method. The QR code is a backup option.

### Alternative Sharing Methods

If email is not configured or fails:
1. **Copy invitation link** - Use the copy button in the dialog
2. **Copy invitation code** - Share the code manually (8-4-4 format)
3. **QR code** - Share screenshot of QR code (works if same network)

## Testing

1. Configure email in `.env`
2. Restart backend server
3. Create a company with an admin email
4. Check email inbox for invitation
5. Click link or use code to complete registration

## Troubleshooting

### Email Not Sending
- Check SMTP credentials in `.env`
- Verify email service is enabled (Gmail, SendGrid, etc.)
- Check server logs for SMTP errors
- Email sending is non-blocking - invitation is still created even if email fails

### Invitation Link Not Working
- Verify `APP_BASE_URL` is correct in `.env`
- Ensure the URL is publicly accessible
- Check if the app route `/register?token=XXX` exists

### QR Code Not Scanning
- QR code uses `APP_BASE_URL` - ensure it's not localhost in production
- QR codes work best when sender and receiver are on the same network (dev)
- For production, email is the primary method



