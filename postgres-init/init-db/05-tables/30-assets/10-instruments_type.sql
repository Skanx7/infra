CREATE TABLE IF NOT EXISTS assets.instruments_type(
    type_code VARCHAR(10) NOT NULL UNIQUE,
    label TEXT NOT NULL
);

    INSERT INTO assets.instruments_type (type_code, label) VALUES
    ('S', 'Stock'),
    ('O', 'Option'),
    ('C', 'Commodity'),
    ('D', 'Debt'),
    ('F', 'Forex'),
    ('E', 'ETF'),
    ('CR', 'Cryptocurrency')
    ON CONFLICT (type_code) DO NOTHING;