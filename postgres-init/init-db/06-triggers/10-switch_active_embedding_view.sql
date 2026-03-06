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