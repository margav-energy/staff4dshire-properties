-- Xero Integration Tables
-- Add these to your existing schema

-- Xero Connections Table
CREATE TABLE xero_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id VARCHAR(255) NOT NULL,
    tenant_name VARCHAR(255),
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tenant_id)
);

-- Xero Invoice Sync Table
CREATE TABLE xero_invoice_sync (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    timesheet_entry_id UUID REFERENCES time_entries(id) ON DELETE CASCADE,
    xero_invoice_id VARCHAR(255) NOT NULL,
    xero_invoice_number VARCHAR(100),
    contact_id VARCHAR(255),
    sync_status VARCHAR(50) NOT NULL CHECK (sync_status IN ('pending', 'synced', 'failed', 'cancelled')),
    error_message TEXT,
    synced_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Xero Contact Mapping Table
CREATE TABLE xero_contact_mapping (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    xero_contact_id VARCHAR(255) NOT NULL,
    xero_contact_name VARCHAR(255),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, project_id)
);

-- Indexes for Performance
CREATE INDEX idx_xero_connections_user_id ON xero_connections(user_id);
CREATE INDEX idx_xero_connections_tenant_id ON xero_connections(tenant_id);
CREATE INDEX idx_xero_invoice_sync_timesheet_entry_id ON xero_invoice_sync(timesheet_entry_id);
CREATE INDEX idx_xero_invoice_sync_xero_invoice_id ON xero_invoice_sync(xero_invoice_id);
CREATE INDEX idx_xero_invoice_sync_status ON xero_invoice_sync(sync_status);
CREATE INDEX idx_xero_contact_mapping_user_id ON xero_contact_mapping(user_id);
CREATE INDEX idx_xero_contact_mapping_project_id ON xero_contact_mapping(project_id);

-- Trigger for Updated At
CREATE TRIGGER update_xero_connections_updated_at BEFORE UPDATE ON xero_connections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_xero_invoice_sync_updated_at BEFORE UPDATE ON xero_invoice_sync
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_xero_contact_mapping_updated_at BEFORE UPDATE ON xero_contact_mapping
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


