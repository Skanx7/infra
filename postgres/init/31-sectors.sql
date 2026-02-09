CREATE TABLE IF NOT EXISTS assets.sectors (
    id SERIAL PRIMARY KEY,
    classification_id INT,,
    sector_name TEXT NOT NULL,
    parent_id INT REFERENCES assets.sectors(id),
    level INT NOT NULL,
    classification_id INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (sector_name, level, parent_id),
    FOREIGN KEY (classification_id) REFERENCES assets.sectors_classifications(id) ON DELETE SET NULL
);

CREATE INDEX idx_sectors_parent ON assets.sectors(parent_id);