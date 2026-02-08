
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
---------------------- Table to register which embedding tables to create based on model_key and content_type ---------------------
CREATE TABLE IF NOT EXISTS embedding_registry (
    model_key TEXT NOT NULL,
    content_type TEXT NOT NULL,
    
    table_name TEXT GENERATED ALWAYS AS (
        normalize_identifier(model_key || '_' || content_type)
    ) STORED,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (model_key, content_type),
    FOREIGN KEY (model_key) REFERENCES embedding_models(model_key) ON DELETE CASCADE
);

CALL set_auto_update('embedding_registry');

--------------------- Trigger to auto-create embedding tables ---------------------
CREATE OR REPLACE FUNCTION trigger_create_embedding_table()
RETURNS TRIGGER AS $$
DECLARE
    dims INTEGER;
BEGIN
    SELECT embedding_dim INTO dims 
    FROM embedding_models 
    WHERE model_key = NEW.model_key;

    IF dims IS NULL THEN
        RAISE EXCEPTION 'Model % not recognized', NEW.model_key;
    END IF;
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I (
            record_id UUID NOT NULL,
            published_at TIMESTAMPTZ NOT NULL,
            chunk_index INTEGER NOT NULL DEFAULT 0,
            embedding vector(%s),
            
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),

            PRIMARY KEY (record_id, chunk_index, published_at)
        )', NEW.table_name, dims);
        
    PERFORM create_hypertable(NEW.table_name, 'published_at', if_not_exists => TRUE);

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS %I 
        ON %I USING hnsw (embedding vector_cosine_ops)', 
        NEW.table_name || '_vec_idx', NEW.table_name);

    EXECUTE format('CALL set_auto_update(%L)', NEW.table_name);

    RAISE NOTICE 'Table % created (dim=%)', NEW.table_name, dims;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE setup_embedding_trigger()
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE '
        CREATE OR REPLACE TRIGGER create_embedding_table_trigger
        AFTER INSERT ON embedding_registry
        FOR EACH ROW
        EXECUTE FUNCTION trigger_create_embedding_table()';
END;
$$;

CALL setup_embedding_trigger();

--------------------- Function to retrieve embeddings from the correct table based on model_key and content_type ---------------------

CREATE OR REPLACE FUNCTION get_embedding_table(
    target_key TEXT, 
    target_type TEXT DEFAULT 'news'
)
RETURNS TABLE (
    record_id UUID,
    published_at TIMESTAMPTZ,
    embedding VECTOR,
    dim_check INTEGER
) AS $$
DECLARE
    target_table TEXT;
    target_dim INTEGER;
BEGIN
    SELECT table_name, embedding_dim 
    INTO target_table, target_dim
    FROM embedding_registry er 
    JOIN embedding_models em ON er.model_key = em.model_key
    WHERE er.model_key = target_key AND er.content_type = target_type;

    IF target_table IS NULL THEN
        RAISE EXCEPTION 'Table introuvable pour % / %', target_key, target_type;
    END IF;

    -- Pas de cast complexe, on lit juste la colonne "embedding"
    RETURN QUERY EXECUTE format(
        'SELECT record_id, published_at, embedding, %L::INTEGER FROM %I', 
        target_dim, target_table
    );
END;
$$ LANGUAGE plpgsql;
