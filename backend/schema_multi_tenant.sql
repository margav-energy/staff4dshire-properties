-- Multi-Tenant Schema Migration
-- Adds company/organization isolation to the database

-- Companies/Organizations Table
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255), -- Optional: company domain for email matching
    address TEXT,
    phone_number VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    subscription_tier VARCHAR(50) DEFAULT 'basic', -- basic, premium, enterprise
    max_users INTEGER DEFAULT 50,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add company_id to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_superadmin BOOLEAN DEFAULT FALSE;

-- Update role check to include superadmin
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('staff', 'supervisor', 'admin', 'superadmin'));

-- Add company_id to projects table
ALTER TABLE projects 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to time_entries table
ALTER TABLE time_entries 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to documents table
ALTER TABLE documents 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to fit_to_work_declarations table
ALTER TABLE fit_to_work_declarations 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to rams_signoffs table
ALTER TABLE rams_signoffs 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to toolbox_talk_attendance table
ALTER TABLE toolbox_talk_attendance 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to notifications table
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to inductions table
ALTER TABLE inductions 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Add company_id to job_completions table (if exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_completions') THEN
        ALTER TABLE job_completions 
        ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add company_id to invoices table (if exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'invoices') THEN
        ALTER TABLE invoices 
        ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add company_id to incidents table (if exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'incidents') THEN
        ALTER TABLE incidents 
        ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_is_superadmin ON users(is_superadmin);
CREATE INDEX IF NOT EXISTS idx_projects_company_id ON projects(company_id);
CREATE INDEX IF NOT EXISTS idx_time_entries_company_id ON time_entries(company_id);
CREATE INDEX IF NOT EXISTS idx_documents_company_id ON documents(company_id);

-- Create function to automatically set company_id for time_entries based on user
CREATE OR REPLACE FUNCTION set_time_entry_company_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.company_id IS NULL THEN
        SELECT company_id INTO NEW.company_id 
        FROM users 
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for time_entries
DROP TRIGGER IF EXISTS trigger_set_time_entry_company_id ON time_entries;
CREATE TRIGGER trigger_set_time_entry_company_id
    BEFORE INSERT OR UPDATE ON time_entries
    FOR EACH ROW
    EXECUTE FUNCTION set_time_entry_company_id();

-- Create default company for existing data (migration support)
INSERT INTO companies (id, name, domain, is_active)
VALUES (
    '00000000-0000-0000-0000-000000000001'::UUID,
    'Default Company',
    NULL,
    TRUE
)
ON CONFLICT DO NOTHING;

-- Update existing users to belong to default company (if company_id is NULL)
UPDATE users 
SET company_id = '00000000-0000-0000-0000-000000000001'::UUID
WHERE company_id IS NULL;

-- Update existing projects to belong to default company
UPDATE projects 
SET company_id = '00000000-0000-0000-0000-000000000001'::UUID
WHERE company_id IS NULL;

-- Update other tables similarly
UPDATE time_entries 
SET company_id = (SELECT company_id FROM users WHERE users.id = time_entries.user_id)
WHERE company_id IS NULL;

UPDATE documents 
SET company_id = (SELECT company_id FROM users WHERE users.id = documents.user_id)
WHERE company_id IS NULL;

UPDATE notifications 
SET company_id = (SELECT company_id FROM users WHERE users.id = notifications.user_id)
WHERE company_id IS NULL;

-- Add constraint: non-superadmin users must have a company_id
ALTER TABLE users 
ADD CONSTRAINT users_company_required 
CHECK (is_superadmin = TRUE OR company_id IS NOT NULL);



