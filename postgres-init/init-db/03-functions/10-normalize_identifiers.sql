CREATE OR REPLACE FUNCTION normalize_identifier(input TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    normalized TEXT;
BEGIN
    normalized := regexp_replace(lower(input), '[^a-z0-9_]+', '_', 'g');

    IF normalized ~ '^[a-z_]' THEN
        RETURN normalized;
    END IF;

    RETURN 't_' || normalized;
END;
$$;
