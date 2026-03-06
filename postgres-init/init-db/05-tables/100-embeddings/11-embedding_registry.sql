CREATE TABLE IF NOT EXISTS embeddings.embedding_registry (
    model_key TEXT PRIMARY KEY,
    table_name TEXT GENERATED ALWAYS AS (
        normalize_identifier(model_key || '_documents')
    ) STORED,
    
    is_default BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    FOREIGN KEY (model_key) REFERENCES embeddings.embedding_models(model_key) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_active_model 
ON embeddings.embedding_registry (is_default) 
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
    
    -- Creates ONE table per model that holds ALL content types
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %s (
            record_id UUID NOT NULL,
            published_at TIMESTAMPTZ NOT NULL,
            
            content_type TEXT NOT NULL, -- (e.g., ''news'', ''wiki'', ''tweet'')
            
            chunk_content TEXT,
            chunk_index INTEGER NOT NULL DEFAULT 0,
            embedding vector(%s),
            
            metadata JSONB DEFAULT ''{}''::jsonb,
            fts tsvector GENERATED ALWAYS AS (to_tsvector(''english'', coalesce(chunk_content, ''''))) STORED,
            
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),

            PRIMARY KEY (record_id, chunk_index, published_at, content_type)
        )', full_table_name, dims);
        
    BEGIN
        -- TimescaleDB handles the time-series partitioning flawlessly here
        PERFORM create_hypertable(full_table_name, 'published_at', if_not_exists => TRUE);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Table % skipped hypertable creation.', full_table_name;
    END;

    -- THE MAGIC: Partial HNSW Indexes
    -- Postgres creates separate, small indexes in RAM for your main domains
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING HNSW (embedding vector_cosine_ops) WHERE content_type = ''news''', NEW.table_name || '_vec_news_', full_table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING HNSW (embedding vector_cosine_ops) WHERE content_type = ''wiki''', NEW.table_name || '_vec_wiki_', full_table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING HNSW (embedding vector_cosine_ops) WHERE content_type = ''tweet''', NEW.table_name || '_vec_tweet_', full_table_name);

    -- Keyword and Metadata Indexes
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING GIN (fts)', NEW.table_name || '_fts_idx_', full_table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING GIN (metadata)', NEW.table_name || '_meta_idx_', full_table_name);

    EXECUTE format('CALL set_auto_update(%L)', full_table_name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER create_embedding_table_trigger
AFTER INSERT ON embeddings.embedding_registry
FOR EACH ROW EXECUTE FUNCTION trigger_create_embedding_table();

CREATE OR REPLACE FUNCTION refresh_active_embedding_view()
RETURNS TRIGGER AS $$
BEGIN
    EXECUTE format('
        CREATE OR REPLACE VIEW embeddings.active_documents AS 
        SELECT 
            record_id, 
            published_at, 
            content_type,
            chunk_index, 
            chunk_content, 
            embedding,
            metadata,
            fts,
            %L::text AS model_key
        FROM embeddings.%I', 
        NEW.model_key, NEW.table_name
    );
    
    RAISE NOTICE 'View embeddings.active_documents now points to table %', NEW.table_name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auto_switch_embedding_view
    AFTER INSERT OR UPDATE OF is_default ON embeddings.embedding_registry
    FOR EACH ROW WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION refresh_active_embedding_view();