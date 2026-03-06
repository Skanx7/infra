CREATE TABLE IF NOT EXISTS companies.company_identifiers (
    identifier_id UUID PRIMARY KEY DEFAULT uuidv7(),
    company_id UUID REFERENCES companies.companies(company_id) ON DELETE CASCADE,
    
    identifier_type VARCHAR(20) NOT NULL,   -- 'LEI', 'CIK', 'TAX_ID'
    identifier_value VARCHAR(50) NOT NULL,
    
    is_primary BOOLEAN DEFAULT FALSE,
    
    valid_from DATE,
    valid_to DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE (company_id, identifier_type, identifier_value)
);

CREATE INDEX idx_identifiers_search ON companies.company_identifiers(identifier_type, identifier_value);
CALL set_auto_update('companies.company_identifiers');