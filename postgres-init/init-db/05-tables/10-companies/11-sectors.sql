CREATE TABLE IF NOT EXISTS companies.sectors (
    id SERIAL PRIMARY KEY,
    classification_id INT REFERENCES companies.sector_classifications(id) ON DELETE SET NULL,
    sector_name TEXT NOT NULL,
    parent_id INT REFERENCES companies.sectors(id),
    level INT NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (sector_name, level, parent_id)
);

CREATE INDEX idx_sectors_parent ON companies.sectors(parent_id);


CALL set_auto_update('companies.sectors');