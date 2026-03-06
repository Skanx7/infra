
CREATE TABLE IF NOT EXISTS companies.sector_classifications (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    organization TEXT,
    level_names TEXT[] NOT NULL,
    description TEXT,
    levels_count INT GENERATED ALWAYS AS (array_length(level_names, 1)) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CALL set_auto_update('companies.sector_classifications');