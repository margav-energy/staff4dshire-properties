# Login Credentials - Development Mode

## 🔓 Development Login (Mock Authentication)

The app currently uses **mock authentication** for development. This means you can log in with any valid email/password format!

## ✅ Test Credentials

### Any Email/Password Works!

**Requirements:**
- Email: Must contain `@` (e.g., `test@example.com`)
- Password: Must be at least 6 characters (e.g., `password123`)

### Role-Based Login (Automatic)

The system automatically determines your role based on your email:

#### 👷 Staff User
```
Email: staff@staff4dshire.com
Password: password123
```
Or any email that doesn't contain "admin" or "supervisor"

#### 👔 Supervisor User
```
Email: supervisor@staff4dshire.com
Password: password123
```
Or any email containing "supervisor" or "super"

#### 👑 Admin User
```
Email: admin@staff4dshire.com
Password: password123
```
Or any email containing "admin"

## 🚀 Quick Login Examples

**Staff Dashboard:**
- Email: `john@example.com`
- Password: `123456`

**Supervisor Dashboard:**
- Email: `supervisor@example.com`
- Password: `password`

**Admin Dashboard:**
- Email: `admin@example.com`
- Password: `admin123`

## 🔐 Login Requirements

The login form validates:
- ✅ Email format (must contain `@`)
- ✅ Password length (minimum 6 characters)

**Any credentials meeting these requirements will work!**

## 📝 Example Workflow

1. **Open the app** (should show login screen)
2. **Enter any valid email** (e.g., `test@test.com`)
3. **Enter any password** (minimum 6 characters, e.g., `test123`)
4. **Click "Sign In"**
5. **You'll be logged in** and see the appropriate dashboard

## 🎭 Testing Different Roles

To see different dashboards:

1. **Staff View:** Use any regular email
   - `staff@test.com` / `password`

2. **Supervisor View:** Use email with "supervisor"
   - `supervisor@test.com` / `password`

3. **Admin View:** Use email with "admin"
   - `admin@test.com` / `password`

## ⚠️ Important Notes

- This is **development mode** - no real authentication
- All logins succeed if format is valid
- No actual user verification
- For production, you'll need to connect to a real backend API

## 🔧 For Production

Later, when you connect to a real backend:
1. Replace `AuthProvider.login()` with actual API call
2. Remove mock user data
3. Implement real authentication tokens
4. Add password hashing/verification
5. Connect to your PostgreSQL database

## 📚 Next Steps

1. Try logging in with different role emails
2. Explore the different dashboards
3. Test all the features
4. When ready, connect to your backend API

---

**Remember:** For now, **any valid email/password format will work!** Just make sure:
- Email has `@`
- Password is 6+ characters

Enjoy testing! 🎉

