-- Company Invitations Table
-- Allows companies to invite admins to complete their registration

CREATE TABLE IF NOT EXISTS company_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invitation_token VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'supervisor')),
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL, -- Superadmin who created the invitation
    expires_at TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    used_at TIMESTAMP NULL, -- When the invitation was used to complete registration
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



