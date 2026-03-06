CREATE TABLE IF NOT EXISTS companies.company_sectors (
    company_id UUID REFERENCES companies.companies(company_id) ON DELETE CASCADE,
    sector_id INT REFERENCES companies.sectors(id) ON DELETE RESTRICT,

    is_primary BOOLEAN DEFAULT FALSE,   -- Does the description of the company primarily fit this sector?
    revenue_share DECIMAL(5,4),         -- share of the revenue for this sector
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    PRIMARY KEY (company_id, sector_id)

);


CREATE INDEX idx_company_sectors_company ON companies.company_sectors(company_id);
CREATE INDEX idx_company_sectors_sector ON companies.company_sectors(sector_id);