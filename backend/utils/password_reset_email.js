// Password reset email template - extracted for reuse
function getPasswordResetEmailHtml(resetCode, firstName, baseUrl) {
  const isLocalhost = baseUrl.includes('localhost') || baseUrl.includes('127.0.0.1');
  // GoRouter on Flutter web uses hash-based routing (#/), so we need to include the hash
  // Remove any trailing slash and ensure hash routing format
  const cleanBaseUrl = baseUrl.replace(/\/$/, '');
  const resetLink = `${cleanBaseUrl}/#/reset-password?code=${resetCode}`;
  
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Password Reset Request</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          background-color: #f5f5f5;
        }
        .container {
          background-color: #ffffff;
          border-radius: 8px;
          padding: 40px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
          text-align: center;
          margin-bottom: 30px;
        }
        .logo {
          font-size: 32px;
          font-weight: bold;
          color: #1976d2;
          margin-bottom: 10px;
        }
        h1 {
          color: #333;
          margin-bottom: 20px;
        }
        .button {
          display: inline-block;
          padding: 12px 24px;
          background-color: #1976d2;
          color: #ffffff !important;
          text-decoration: none;
          border-radius: 4px;
          margin: 20px 0;
          font-weight: bold;
        }
        .button:hover {
          background-color: #1565c0;
        }
        .footer {
          margin-top: 30px;
          padding-top: 20px;
          border-top: 1px solid #e0e0e0;
          font-size: 12px;
          color: #666;
          text-align: center;
        }
        .code-box {
          background-color: #f5f5f5;
          padding: 30px;
          border-radius: 8px;
          margin: 30px 0;
          text-align: center;
          border: 3px solid #1976d2;
        }
        .code {
          font-size: 48px;
          font-weight: bold;
          color: #1976d2;
          letter-spacing: 12px;
          font-family: monospace;
          margin: 10px 0;
        }
        .warning {
          background-color: #fff3cd;
          border-left: 4px solid #ffc107;
          padding: 12px;
          margin: 20px 0;
        }
        .info {
          background-color: #e7f3ff;
          border-left: 4px solid #2196F3;
          padding: 12px;
          margin: 20px 0;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">S4P</div>
          <h1>Staff4dshire Properties</h1>
        </div>
        
        <p>Hello ${firstName},</p>
        
        <p>We received a request to reset your password for your Staff4dshire Properties admin account.</p>
        
        <div class="code-box">
          <p style="margin: 0 0 10px 0; font-size: 14px; color: #666;">Your password reset code is:</p>
          <div class="code">${resetCode}</div>
        </div>
        
        <p style="text-align: center;">Click the button below to go to the reset password page:</p>
        <div style="text-align: center;">
          <a href="${resetLink}" class="button">Reset Password</a>
        </div>
        
        <p style="text-align: center; margin-top: 10px;">Or copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #1976d2; text-align: center;">${resetLink}</p>
        
        ${isLocalhost ? `
          <div class="info">
            <strong>💡 Development Environment:</strong> If you can't click the link, 
            navigate to your password reset page and enter the code above manually.
          </div>
        ` : ''}
        
        <div class="warning">
          <strong>⏰ Important:</strong> This code will expire in 1 hour for security reasons.
        </div>
        
        <p>If you didn't request a password reset, please ignore this email. Your password will remain unchanged.</p>
        
        <div class="footer">
          <p>© ${new Date().getFullYear()} Staff4dshire Properties. All rights reserved.</p>
          <p>This is an automated email, please do not reply.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

module.exports = { getPasswordResetEmailHtml };
