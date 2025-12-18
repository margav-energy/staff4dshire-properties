const nodemailer = require('nodemailer');
require('dotenv').config();

// Create reusable transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

// Verify connection configuration
transporter.verify(function (error, success) {
  if (error) {
    console.log('Email service configuration error:', error);
  } else {
    console.log('Email service is ready to send messages');
  }
});

/**
 * Send invitation email
 * @param {string} to - Recipient email
 * @param {string} invitationToken - Invitation token
 * @param {string} companyName - Company name
 * @param {string} role - Admin role
 * @param {Date} expiresAt - Expiration date
 * @param {string} baseUrl - Base URL for the app (e.g., https://app.staff4dshire.com or http://localhost:3000 for dev)
 */
async function sendInvitationEmail(to, invitationToken, companyName, role, expiresAt, baseUrl) {
  const invitationLink = `${baseUrl}/register?token=${invitationToken}`;
  const expiresDate = new Date(expiresAt).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });

  const mailOptions = {
    from: process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@staff4dshire.com',
    to: to,
    subject: `Invitation to join ${companyName} on Staff4dshire Properties`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Company Invitation</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background-color: #4a026f;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 8px 8px 0 0;
          }
          .content {
            background-color: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
            border-top: none;
            border-radius: 0 0 8px 8px;
          }
          .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #4a026f;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
          }
          .code-box {
            background-color: #e9e9e9;
            padding: 15px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 18px;
            text-align: center;
            margin: 20px 0;
            letter-spacing: 2px;
          }
          .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            font-size: 12px;
            color: #666;
            text-align: center;
          }
          .warning {
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Staff4dshire Properties</h1>
        </div>
        <div class="content">
          <h2>You've been invited!</h2>
          <p>Hello,</p>
          <p>You have been invited to join <strong>${companyName}</strong> as a <strong>${role}</strong> on Staff4dshire Properties.</p>
          
          <p>Click the button below to complete your registration:</p>
          
          <div style="text-align: center;">
            <a href="${invitationLink}" class="button">Accept Invitation & Register</a>
          </div>
          
          <p style="margin-top: 30px;">Or copy and paste this link into your browser:</p>
          <p style="word-break: break-all; color: #4a026f;">${invitationLink}</p>
          
          <p style="margin-top: 30px;">Alternatively, you can use this invitation code:</p>
          <div class="code-box">${invitationToken}</div>
          <p style="text-align: center; font-size: 14px;">Enter this code in the app's registration screen</p>
          
          <div class="warning">
            <strong>⚠️ Important:</strong> This invitation expires on ${expiresDate}. Please complete your registration before then.
          </div>
          
          <p>If you didn't expect this invitation, please ignore this email.</p>
        </div>
        <div class="footer">
          <p>This is an automated message from Staff4dshire Properties.</p>
          <p>If you have any questions, please contact your company administrator.</p>
        </div>
      </body>
      </html>
    `,
    text: `
You've been invited to join ${companyName} as a ${role} on Staff4dshire Properties.

Click this link to complete your registration:
${invitationLink}

Or use this invitation code: ${invitationToken}

This invitation expires on ${expiresDate}.

If you didn't expect this invitation, please ignore this email.
    `.trim(),
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Invitation email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending invitation email:', error);
    throw error;
  }
}

/**
 * Send notification email to superadmins about new invitation request
 * @param {Object} request - Invitation request object
 */
async function sendInvitationRequestNotificationEmail(request) {
  // Get all superadmin emails
  // Note: This requires database access, so we'll need to pass pool or get emails from request handler
  // For now, we'll use environment variable for superadmin notification email
  const superadminEmail = process.env.SUPERADMIN_EMAIL || process.env.SMTP_USER;
  
  if (!superadminEmail) {
    console.warn('No superadmin email configured. Skipping invitation request notification.');
    return;
  }

  const mailOptions = {
    from: process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@staff4dshire.com',
    to: superadminEmail,
    subject: `New Admin Invitation Request - ${request.first_name} ${request.last_name}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>New Invitation Request</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background-color: #4a026f;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 8px 8px 0 0;
          }
          .content {
            background-color: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
            border-top: none;
            border-radius: 0 0 8px 8px;
          }
          .info-box {
            background-color: white;
            padding: 15px;
            border-radius: 5px;
            margin: 15px 0;
            border-left: 4px solid #4a026f;
          }
          .info-label {
            font-weight: bold;
            color: #4a026f;
            margin-right: 10px;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>New Admin Invitation Request</h1>
        </div>
        <div class="content">
          <p>A new admin access request has been submitted:</p>
          
          <div class="info-box">
            <p><span class="info-label">Name:</span> ${request.first_name} ${request.last_name}</p>
            <p><span class="info-label">Email:</span> ${request.email}</p>
            ${request.company_name ? `<p><span class="info-label">Company:</span> ${request.company_name}</p>` : ''}
            ${request.phone_number ? `<p><span class="info-label">Phone:</span> ${request.phone_number}</p>` : ''}
            ${request.message ? `<p><span class="info-label">Message:</span> ${request.message}</p>` : ''}
            <p><span class="info-label">Requested:</span> ${new Date(request.created_at).toLocaleString('en-GB')}</p>
          </div>
          
          <p>Please review this request in the admin dashboard and approve or reject it accordingly.</p>
        </div>
      </body>
      </html>
    `,
    text: `
New Admin Invitation Request

A new admin access request has been submitted:

Name: ${request.first_name} ${request.last_name}
Email: ${request.email}
${request.company_name ? `Company: ${request.company_name}` : ''}
${request.phone_number ? `Phone: ${request.phone_number}` : ''}
${request.message ? `Message: ${request.message}` : ''}
Requested: ${new Date(request.created_at).toLocaleString('en-GB')}

Please review this request in the admin dashboard.
    `.trim(),
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Invitation request notification email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending invitation request notification email:', error);
    throw error;
  }
}

/**
 * Send credentials email to new admin
 * @param {string} to - Recipient email
 * @param {string} password - Plain text password (to be changed on first login)
 * @param {string} firstName - User's first name
 * @param {string} companyName - Company name
 * @param {string} baseUrl - Base URL for the app
 */
async function sendCredentialsEmail(to, password, firstName, companyName, baseUrl) {
  // If baseUrl is localhost, don't include clickable link (won't work in email)
  const isLocalhost = baseUrl.includes('localhost') || baseUrl.includes('127.0.0.1');
  const loginUrl = isLocalhost ? null : `${baseUrl}/login`;
  const loginInstructions = isLocalhost 
    ? `Please open your admin app or navigate to the login page manually.`
    : `Click the button below or visit: ${baseUrl}/login`;

  const mailOptions = {
    from: process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@staff4dshire.com',
    to: to,
    subject: `Welcome to Staff4dshire Properties - Your Admin Account Credentials`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Your Admin Account Credentials</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background-color: #4a026f;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 8px 8px 0 0;
          }
          .content {
            background-color: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
            border-top: none;
            border-radius: 0 0 8px 8px;
          }
          .button {
            display: inline-block;
            padding: 12px 24px;
            background-color: #4a026f;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
          }
          .credentials-box {
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            border: 2px solid #4a026f;
            margin: 20px 0;
          }
          .credential-item {
            margin: 10px 0;
            padding: 10px;
            background-color: #f5f5f5;
            border-radius: 5px;
          }
          .credential-label {
            font-weight: bold;
            color: #4a026f;
            display: block;
            margin-bottom: 5px;
          }
          .credential-value {
            font-family: monospace;
            font-size: 16px;
            color: #333;
            word-break: break-all;
          }
          .warning {
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
          }
          .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
            font-size: 12px;
            color: #666;
            text-align: center;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Welcome to Staff4dshire Properties!</h1>
        </div>
        <div class="content">
          <h2>Hello ${firstName},</h2>
          <p>Your admin account for <strong>${companyName}</strong> has been created successfully!</p>
          
          <p>Please use the following credentials to log in:</p>
          
          <div class="credentials-box">
            <div class="credential-item">
              <span class="credential-label">Email:</span>
              <span class="credential-value">${to}</span>
            </div>
            <div class="credential-item">
              <span class="credential-label">Password:</span>
              <span class="credential-value">${password}</span>
            </div>
          </div>
          
          ${loginUrl ? `
          <div style="text-align: center;">
            <a href="${loginUrl}" class="button">Log In to Your Account</a>
          </div>
          <p style="text-align: center; margin-top: 10px;">Or copy and paste this link: <span style="word-break: break-all; color: #4a026f;">${loginUrl}</span></p>
          ` : `
          <p style="text-align: center; margin-top: 20px;"><strong>${loginInstructions}</strong></p>
          `}
          
          <div class="warning">
            <strong>🔒 Security Note:</strong> Please change your password after your first login. This is a temporary password for security purposes.
          </div>
          
          <p>If you didn't request this account, please ignore this email or contact support.</p>
        </div>
        <div class="footer">
          <p>This is an automated message from Staff4dshire Properties.</p>
          <p>If you have any questions, please contact your company administrator.</p>
        </div>
      </body>
      </html>
    `,
    text: `
Welcome to Staff4dshire Properties!

Hello ${firstName},

Your admin account for ${companyName} has been created successfully!

Please use the following credentials to log in:

Email: ${to}
Password: ${password}

${loginUrl ? `Log in here: ${loginUrl}` : loginInstructions}

🔒 Security Note: Please change your password after your first login. This is a temporary password for security purposes.

If you didn't request this account, please ignore this email or contact support.
    `.trim(),
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending credentials email:', error);
    throw error;
  }
}

/**
 * Send password reset email
 * @param {string} to - Recipient email
 * @param {string} resetCode - 6-digit password reset code
 * @param {string} firstName - User's first name
 * @param {string} baseUrl - Base URL for the app
 */
async function sendPasswordResetEmail(to, resetCode, firstName, baseUrl) {
  const { getPasswordResetEmailHtml } = require('./password_reset_email');
  
  const mailOptions = {
    from: process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@staff4dshire.com',
    to: to,
    subject: 'Reset Your Password - Staff4dshire Properties',
    html: getPasswordResetEmailHtml(resetCode, firstName, baseUrl),
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`Password reset email sent: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error('Error sending password reset email:', error);
    throw error;
  }
}

module.exports = {
  sendInvitationEmail,
  sendInvitationRequestNotificationEmail,
  sendCredentialsEmail,
  sendPasswordResetEmail,
};

