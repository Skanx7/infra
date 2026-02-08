--------------------- Function to retrieve embeddings from the correct table based on model_key and content_type ---------------------

CREATE OR REPLACE FUNCTION get_embedding_table(
    target_key TEXT, 
    target_type TEXT DEFAULT 'news'
)
RETURNS TABLE (
    record_id UUID,
    published_at TIMESTAMPTZ,
    chunk_index INTEGER,
    chunk_content TEXT,
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
    RETURN QUERY EXECUTE format(
        'SELECT 
        record_id, 
        published_at,
        chunk_index,
        chunk_content, 
        embedding, %L::INTEGER FROM %I', 
        target_dim, target_table
    );
END;
$$ LANGUAGE plpgsql;