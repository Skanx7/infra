CREATE TABLE IF NOT EXISTS companies.company_relationships (
    relationship_id UUID PRIMARY KEY DEFAULT uuidv7(),
    
    parent_id UUID REFERENCES companies.companies(company_id) ON DELETE CASCADE,
    child_id UUID REFERENCES companies.companies(company_id) ON DELETE CASCADE,
    
    relationship_type VARCHAR(50) NOT NULL,
    ownership_percentage NUMERIC(5,2),
    
    valid_from DATE,
    valid_to DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE (parent_id, child_id, relationship_type, valid_from)
);

CREATE INDEX idx_relationships_parent ON companies.company_relationships(parent_id);
CREATE INDEX idx_relationships_child ON companies.company_relationships(child_id);
CALL set_auto_update('companies.company_relationships');