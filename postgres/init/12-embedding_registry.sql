---------- Embedding registry -----------------------------
CREATE TABLE IF NOT EXISTS embeddings.embedding_registry (
    model_key TEXT NOT NULL,
    content_type TEXT NOT NULL,
    
    table_name TEXT GENERATED ALWAYS AS (
        normalize_identifier(model_key || '_' || content_type)
    ) STORED,
    
    is_default BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (model_key, content_type),
    FOREIGN KEY (model_key) REFERENCES embeddings.embedding_models(model_key) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_default_per_type 
ON embeddings.embedding_registry (content_type) 
WHERE is_default = TRUE;

CALL set_auto_update('embeddings.embedding_registry');


CREATE OR REPLACE FUNCTION trigger_create_embedding_table()
RETURNS TRIGGER AS $$
DECLARE
    dims INTEGER;
    full_table_name TEXT;
BEGIN
    SELECT embedding_dim INTO dims 
    FROM embeddings.embedding_models 
    WHERE model_key = NEW.model_key;

    IF dims IS NULL THEN
        RAISE EXCEPTION 'Model % not recognized', NEW.model_key;
    END IF;
    full_table_name := format('embeddings.%I', NEW.table_name);
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %s (
            record_id UUID NOT NULL,
            published_at TIMESTAMPTZ NOT NULL,
            chunk_content TEXT,
            chunk_index INTEGER NOT NULL DEFAULT 0,
            embedding vector(%s),
            
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),

            PRIMARY KEY (record_id, chunk_index, published_at)
        )', full_table_name, dims);
        
    BEGIN
        PERFORM create_hypertable(full_table_name, 'published_at', if_not_exists => TRUE);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Table % is not a time-series table or already exists, skipping hypertable creation.', full_table_name;
    END;

    EXECUTE format('
        CREATE INDEX IF NOT EXISTS %I 
        ON %s USING hnsw (embedding vector_cosine_ops)', 
        NEW.table_name || '_vec_idx_', full_table_name
    );

    EXECUTE format('CALL set_auto_update(%L)', full_table_name);

    RAISE NOTICE 'Table % created (dim=%)', NEW.table_name, dims;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER create_embedding_table_trigger
AFTER INSERT ON embeddings.embedding_registry
FOR EACH ROW
EXECUTE FUNCTION trigger_create_embedding_table();


CREATE OR REPLACE FUNCTION refresh_active_embedding_view()
RETURNS TRIGGER AS $$
DECLARE
    view_name TEXT;
BEGIN
    view_name := NEW.content_type || '_embeddings'; 
    EXECUTE format('
        CREATE OR REPLACE VIEW embeddings.%I AS 
        SELECT 
            record_id, 
            published_at, 
            chunk_index, 
            chunk_content, 
            embedding,
            %L::text AS model_key
        FROM embeddings.%I', 
        view_name, NEW.model_key, NEW.table_name
    );
    
    RAISE NOTICE 'View embeddings.%I now points to table %', view_name, NEW.table_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_switch_embedding_view
    AFTER INSERT OR UPDATE OF is_default ON embeddings.embedding_registry
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION refresh_active_embedding_view();