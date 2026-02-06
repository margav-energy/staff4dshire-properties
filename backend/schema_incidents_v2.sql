-- Incidents Table Schema (v2 - uses gen_random_uuid())
-- Run this after the main schema.sql
-- This version uses gen_random_uuid() which is built-in to PostgreSQL 13+ (no extension needed)

-- Incidents Table
CREATE TABLE IF NOT EXISTS incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    photo_path VARCHAR(500),
    severity VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status VARCHAR(20) NOT NULL DEFAULT 'reported' CHECK (status IN ('reported', 'attending', 'fixing', 'tracking', 'resolved')),
    assigned_to UUID REFERENCES users(id),
    notes TEXT,
    status_updated_at TIMESTAMP,
    status_updated_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_incidents_reporter ON incidents(reporter_id);
CREATE INDEX IF NOT EXISTS idx_incidents_project ON incidents(project_id);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_assigned ON incidents(assigned_to);
CREATE INDEX IF NOT EXISTS idx_incidents_reported_at ON incidents(reported_at);
CREATE INDEX IF NOT EXISTS idx_incidents_company_id ON incidents(company_id);

-- Trigger for updated_at (only if function exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        DROP TRIGGER IF EXISTS update_incidents_updated_at ON incidents;
        CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON incidents
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
