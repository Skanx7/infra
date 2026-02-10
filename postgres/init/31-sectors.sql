CREATE TABLE IF NOT EXISTS assets.sectors (
    id SERIAL PRIMARY KEY,
    classification_id INT REFERENCES assets.sector_classifications(id) ON DELETE SET NULL,
    sector_name TEXT NOT NULL,
    parent_id INT REFERENCES assets.sectors(id),
    level INT NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (sector_name, level, parent_id)
);

CREATE INDEX idx_sectors_parent ON assets.sectors(parent_id);


CALL set_auto_update('assets.sectors');