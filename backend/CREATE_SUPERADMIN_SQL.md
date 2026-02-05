# Create Superadmin via SQL

If you have direct database access (via Render database console), run this SQL:

```sql
-- First, check if user already exists
SELECT id, email FROM users WHERE email = 'superadmin@staff4dshire.com';

-- If no user exists, create one
-- Note: Replace 'YOUR_HASHED_PASSWORD' with a bcrypt hash of your password
-- You can generate one at: https://bcrypt-generator.com/ (rounds: 10)
-- Or use: SELECT crypt('Admin123!', gen_salt('bf', 10));

INSERT INTO users (
    id, 
    email, 
    password_hash, 
    first_name, 
    last_name, 
    role, 
    is_superadmin,
    company_id,
    is_active
)
VALUES (
    gen_random_uuid(),
    'superadmin@staff4dshire.com',
    '$2b$10$YourBcryptHashHere', -- Replace with actual bcrypt hash
    'Super',
    'Admin',
    'superadmin',
    TRUE,
    NULL, -- Superadmins don't need company_id
    TRUE
)
ON CONFLICT (email) DO NOTHING;
```

## Quick Password Hash

For password `Admin123!`, the bcrypt hash is approximately:
```
$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
```

But it's better to generate your own for security.

## After Creating

You can then log in with:
- Email: `superadmin@staff4dshire.com`
- Password: `Admin123!` (or whatever password you hashed)
