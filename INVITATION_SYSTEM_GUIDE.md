# 📧 Staff Invitation System - Production Guide

## How It Works

The invitation system allows admins to invite staff members to join the platform. Staff members use invitation codes to register for accounts.

---

## 🔄 Complete Flow

### Step 1: Admin Creates Invitation

1. **Admin logs in** to the Admin App: `https://staff4dshire-admin.onrender.com`
2. **Goes to User Management** section
3. **Clicks "Invite Staff"** or "Invite Supervisor"
4. **Enters staff email** (optional - can be generic)
5. **Selects role**: Staff or Supervisor
6. **Clicks "Generate Invitation"**

### Step 2: System Generates Invitation Code

- **Unique code generated**: Format `XXXX-XXXX-XXXX` (e.g., `4TFW2J3N-P3JN-UX9E`)
- **Code stored in database** with:
  - Company ID
  - Email (if provided)
  - Role (staff/supervisor)
  - Expiration date (default: 30 days)
  - Invited by (admin user ID)

### Step 3: Admin Shares Code with Staff

**Option A: Email (If SMTP Configured)**
- System automatically sends email with:
  - Invitation code
  - Registration link
  - Company name
  - Expiration date

**Option B: Manual Sharing**
- Admin copies the invitation code from the dialog
- Shares it via:
  - Text message
  - WhatsApp
  - In-person
  - Any communication method

### Step 4: Staff Member Registers

1. **Staff goes to**: `https://staff4dshire-staff.onrender.com`
2. **Clicks "Register"** or "Sign Up"
3. **Enters invitation code** in the "Invitation Code" field
4. **System validates code**:
   - Checks if code exists
   - Checks if code is expired
   - Checks if code is already used
   - Pre-fills email (if provided in invitation)
   - Pre-fills company
5. **Staff completes registration**:
   - First name
   - Last name
   - Email (must match invitation email if provided)
   - Password
   - Profile photo
6. **Account created** and staff can log in

---

## 🔑 Key Features

### Invitation Code Format
- **Format**: `XXXX-XXXX-XXXX` (e.g., `4TFW2J3N-P3JN-UX9E`)
- **Case-insensitive**: `4tfw2j3n-p3jn-ux9e` works the same
- **Unique**: Each code is unique and can only be used once

### Expiration
- **Default**: 30 days from creation
- **Configurable**: Admin can set expiration when creating
- **Expired codes**: Cannot be used, staff must request new invitation

### Email Matching
- **If email provided**: Staff must use the exact email from invitation
- **If no email provided**: Staff can use any email
- **Validation**: System checks email matches invitation

### One-Time Use
- **Each code**: Can only be used once
- **After use**: Code is marked as "used" and cannot be reused
- **Security**: Prevents unauthorized account creation

---

## 📱 For Admins: Creating Invitations

### In Admin App

1. **Navigate to**: User Management → Invite Staff
2. **Fill in**:
   - **Email** (optional): Staff member's email
   - **Role**: Staff or Supervisor
   - **Company**: Automatically set to your company
3. **Click**: "Generate Invitation"
4. **Copy code** from the dialog
5. **Share code** with staff member

### What Happens Behind the Scenes

```javascript
// System generates unique code
const code = "4TFW2J3N-P3JN-UX9E";

// Stores in database
{
  company_id: "your-company-id",
  email: "staff@example.com", // or null
  role: "staff",
  invitation_token: "4TFW2J3N-P3JN-UX9E",
  expires_at: "2024-03-05", // 30 days from now
  used_at: null // null until used
}
```

---

## 👤 For Staff: Using Invitation Codes

### Registration Process

1. **Go to**: `https://staff4dshire-staff.onrender.com`
2. **Click**: "Register" or "Sign Up"
3. **Enter invitation code**: `4TFW2J3N-P3JN-UX9E`
4. **System validates**:
   - ✅ Code exists
   - ✅ Code not expired
   - ✅ Code not used
   - ✅ Email matches (if provided)
5. **Complete form**:
   - First name
   - Last name
   - Email (pre-filled if in invitation)
   - Password
   - Confirm password
   - Profile photo (required)
6. **Submit**: Account created!

### What Happens Behind the Scenes

```javascript
// Staff enters code
const code = "4TFW2J3N-P3JN-UX9E";

// System validates
const invitation = await getInvitationByToken(code);
// Checks: exists, not expired, not used

// Creates account
const user = await createUser({
  email: invitation.email,
  role: invitation.role,
  company_id: invitation.companyId,
  // ... other fields
});

// Marks invitation as used
await markInvitationAsUsed(invitation.id);
```

---

## ⚙️ Configuration

### Email Notifications (Optional)

To enable email invitations, set these environment variables in Render:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@staff4dshire.com
APP_BASE_URL=https://staff4dshire-staff.onrender.com
```

**Without email configured:**
- Invitations still work
- Admin must manually share codes
- Codes are displayed in the admin app

### Expiration Settings

- **Default**: 30 days
- **Configurable**: When creating invitation
- **Maximum**: No limit (set to very high number for long-term codes)

---

## 🔒 Security Features

### Code Uniqueness
- Each code is unique
- System checks for duplicates
- Format: 8-4-4 characters (16 total)

### Expiration
- Codes expire after set time
- Expired codes cannot be used
- Prevents old codes from being misused

### One-Time Use
- Codes can only be used once
- After registration, code is marked as used
- Prevents multiple accounts from same code

### Email Validation
- If email provided, must match exactly
- Prevents unauthorized account creation
- Case-insensitive matching

### Company Isolation
- Each code is tied to a company
- Staff can only join the company from invitation
- Multi-tenant security

---

## 📊 Managing Invitations

### View All Invitations

Admins can view:
- All invitations for their company
- Status: Pending, Used, Expired
- Who created the invitation
- When it expires

### Resend Invitation

If a code is lost or expired:
1. Create a new invitation
2. Share the new code
3. Old code becomes invalid

### Revoke Invitation

- **Cannot revoke** once code is generated
- **Solution**: Wait for expiration or create new invitation
- **Used codes**: Automatically cannot be reused

---

## 🐛 Troubleshooting

### "Invalid invitation code"
- **Check**: Code is entered correctly (no spaces, correct format)
- **Check**: Code hasn't expired
- **Check**: Code hasn't been used already
- **Solution**: Request new invitation from admin

### "Email does not match invitation"
- **Check**: Using the exact email from invitation
- **Check**: No typos or extra spaces
- **Solution**: Use the email provided in invitation

### "Invitation code has expired"
- **Reason**: Code expired (default 30 days)
- **Solution**: Request new invitation from admin

### "Invitation code already used"
- **Reason**: Code was already used to create an account
- **Solution**: Use existing account or request new invitation

### Admin Can't Create Invitation
- **Check**: Logged in as admin/superadmin
- **Check**: Company exists
- **Check**: Backend is running
- **Solution**: Check backend logs for errors

---

## 📝 Best Practices

### For Admins

1. **Share codes securely**: Use secure communication channels
2. **Set appropriate expiration**: 30 days is usually good
3. **Provide email**: Makes registration easier for staff
4. **Keep track**: Note who you've invited
5. **Resend if needed**: Don't hesitate to create new codes

### For Staff

1. **Enter code carefully**: Check for typos
2. **Use correct email**: Must match invitation if provided
3. **Complete profile**: Add photo and all required info
4. **Save password**: You'll need it to log in
5. **Contact admin**: If code doesn't work

---

## 🎯 Summary

**The invitation system works like this:**

1. ✅ Admin creates invitation → Gets unique code
2. ✅ Admin shares code with staff (email or manually)
3. ✅ Staff enters code when registering
4. ✅ System validates code (exists, not expired, not used)
5. ✅ Staff completes registration
6. ✅ Account created and code marked as used
7. ✅ Staff can now log in

**Key Points:**
- Codes are unique and one-time use
- Codes expire (default 30 days)
- Email must match if provided in invitation
- Works with or without email configuration
- Secure and company-isolated

---

## 🔗 Related Files

- **Backend**: `backend/routes/company-invitations.js`
- **Frontend**: `apps/staff_app/lib/features/auth/screens/register_screen.dart`
- **Admin**: `apps/admin_app/lib/features/users/screens/user_management_screen.dart`
- **Email Service**: `backend/utils/emailService.js`
