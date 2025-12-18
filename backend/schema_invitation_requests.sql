-- Invitation Requests Table
-- Allows users to request access to the admin portal
CREATE TABLE IF NOT EXISTS invitation_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

