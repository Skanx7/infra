---------- Embedding registry -----------------------------
CREATE TABLE IF NOT EXISTS embedding_registry (
    model_key TEXT NOT NULL,
    content_type TEXT NOT NULL,
    
    table_name TEXT GENERATED ALWAYS AS (
        normalize_identifier(model_key || '_' || content_type)
    ) STORED,
    
    is_default BOOLEAN DEFAULT FALSE,  -- Flag pour indiquer le modèle par défaut à utiliser pour ce content_type (ex: news)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (model_key, content_type),
    FOREIGN KEY (model_key) REFERENCES embedding_models(model_key) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_default_per_type 
ON embedding_registry (content_type) 
WHERE is_default = TRUE;

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
            chunk_content TEXT,
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


CREATE OR REPLACE TRIGGER create_embedding_table_trigger
AFTER INSERT ON embedding_registry
FOR EACH ROW
EXECUTE FUNCTION trigger_create_embedding_table();


---------- Trigger to refresh the embedding view when the default model changes -----------------------------

--- This will create views like news_embeddings for instance
CREATE OR REPLACE FUNCTION refresh_active_embedding_view()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    view_name TEXT;
BEGIN
    FOR rec IN 
        SELECT model_key, content_type, table_name 
        FROM embedding_registry 
        WHERE is_default = TRUE 
          AND content_type = NEW.content_type
    LOOP
        view_name := rec.content_type || '_embeddings'; 

        EXECUTE format('
            CREATE OR REPLACE VIEW %I AS 
            SELECT 
                record_id, 
                published_at, 
                chunk_index, 
                chunk_content, 
                embedding,
                %L::text AS model_key
            FROM %I', 
            view_name, rec.model_key, rec.table_name
        );
        
        RAISE NOTICE 'View switched: % now points to % (Model: %)', view_name, rec.table_name, rec.model_key;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_switch_embedding_view
    AFTER INSERT OR UPDATE OF is_default ON embedding_registry
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION refresh_active_embedding_view();