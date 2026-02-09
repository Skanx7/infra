CREATE TABLE IF NOT EXISTS assets.company_sectors (
    company_id UUID REFERENCES assets.companies(company_id) ON DELETE CASCADE,
    sector_id INT REFERENCES assets.sectors(id) ON DELETE RESTRICT,

    is_primary BOOLEAN DEFAULT FALSE,   -- Does the description of the company primarily fit this sector?
    revenue_share DECIMAL(5,4),         -- share of the revenue for this sector
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    PRIMARY KEY (company_id, sector_id)

);


CREATE INDEX idx_company_sectors_company ON assets.company_sectors(company_id);
CREATE INDEX idx_company_sectors_sector ON assets.company_sectors(sector_id);