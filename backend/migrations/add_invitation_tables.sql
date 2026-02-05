-- Migration: Add invitation_requests and company_invitations tables
-- This uses gen_random_uuid() which is built into PostgreSQL 13+ (no extension needed)

-- Invitation Requests Table
CREATE TABLE IF NOT EXISTS invitation_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company_name VARCHAR(255),
    phone_number VARCHAR(20),
    message TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP,
    rejected_at TIMESTAMP,
    rejection_reason TEXT,
    approved_by UUID REFERENCES users(id)
);

-- Create a partial unique index to ensure only one pending request per email
CREATE UNIQUE INDEX IF NOT EXISTS idx_invitation_requests_email_pending 
ON invitation_requests(email) 
WHERE status = 'pending';

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_invitation_requests_email ON invitation_requests(email);
CREATE INDEX IF NOT EXISTS idx_invitation_requests_status ON invitation_requests(status);
CREATE INDEX IF NOT EXISTS idx_invitation_requests_created_at ON invitation_requests(created_at DESC);

-- Company Invitations Table (only if companies table exists)
CREATE TABLE IF NOT EXISTS company_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'supervisor')),
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    expires_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    used_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast lookup by token
CREATE INDEX IF NOT EXISTS idx_company_invitations_token ON company_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_company_invitations_email ON company_invitations(email);
CREATE INDEX IF NOT EXISTS idx_company_invitations_company_id ON company_invitations(company_id);

-- Function to generate invitation token
CREATE OR REPLACE FUNCTION generate_invitation_token()
RETURNS TEXT AS $$
BEGIN
    RETURN upper(
        substring(md5(random()::text || clock_timestamp()::text) from 1 for 8) || 
        '-' ||
        substring(md5(random()::text || clock_timestamp()::text) from 1 for 4) || 
        '-' ||
        substring(md5(random()::text || clock_timestamp()::text) from 1 for 4)
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_company_invitations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_company_invitations_updated_at
BEFORE UPDATE ON company_invitations
FOR EACH ROW
EXECUTE FUNCTION update_company_invitations_updated_at();
