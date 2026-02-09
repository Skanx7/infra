DO $$
DECLARE
    json_path TEXT := '/docker-entrypoint-initdb.d/seeds/embedding_models.json';
    json_oid OID;
    json_data JSONB;
BEGIN

    SELECT lo_import(json_path) INTO json_oid;
    SELECT convert_from(lo_get(json_oid), 'UTF8')::jsonb INTO json_data;

    PERFORM lo_unlink(json_oid);

    INSERT INTO embedding_models (model_key, model_name, embedding_dim, provider, metadata)
    SELECT 
        item->>'model_key',
        item->>'model_name',
        (item->>'embedding_dim')::INTEGER,
        COALESCE(item->>'provider', 'local'),
        COALESCE(item->'metadata', '{}'::jsonb)
    FROM jsonb_array_elements(json_data) AS item
    ON CONFLICT (model_key) 
    DO UPDATE SET 
        model_name = EXCLUDED.model_name,
        embedding_dim = EXCLUDED.embedding_dim,
        provider = EXCLUDED.provider,
        metadata = embedding_models.metadata || EXCLUDED.metadata,
        updated_at = NOW();
        
    RAISE NOTICE 'Embedding models loaded from %', json_path;
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Failed to load embedding models from % : %', json_path, SQLERRM;
END $$;

INSERT INTO embedding_registry (model_key, content_type)
SELECT model_key, 'news'
FROM embedding_models
WHERE model_key IN ('bge-m3', 'snowflake-arctic-l')
ON CONFLICT DO NOTHING;