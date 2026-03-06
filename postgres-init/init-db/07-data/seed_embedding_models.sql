INSERT INTO embeddings.embedding_models (model_key, model_name, embedding_dim, provider, metadata)
VALUES
    -- OpenAI Models
    ('openai-3-small', 'text-embedding-3-small', 1536, 'openai', '{"max_tokens": 8191, "multilingual": true, "matryoshka_support": true}'),
    ('openai-3-large', 'text-embedding-3-large', 3072, 'openai', '{"max_tokens": 8191, "multilingual": true, "matryoshka_support": true}'),
    ('openai-ada-002', 'text-embedding-ada-002', 1536, 'openai', '{"max_tokens": 8191, "multilingual": true}'),

    -- Google (Gemini/Vertex)
    ('google-embed-004', 'text-embedding-004', 768, 'google', '{"max_tokens": 2048, "multilingual": true}'),

    -- Cohere
    ('cohere-eng-v3', 'embed-english-v3.0', 1024, 'cohere', '{"max_tokens": 512, "multilingual": false}'),
    ('cohere-multi-v3', 'embed-multilingual-v3.0', 1024, 'cohere', '{"max_tokens": 512, "multilingual": true}'),

    -- Mistral
    ('mistral-embed', 'mistral-embed', 1024, 'mistral', '{"max_tokens": 8192, "multilingual": true}'),

    -- Voyage AI
    ('voyage-3', 'voyage-3', 1024, 'voyage', '{"max_tokens": 32000, "multilingual": true}'),
    ('voyage-3-large', 'voyage-3-large', 1024, 'voyage', '{"max_tokens": 32000, "multilingual": true}'),

    -- BAAI (BGE - High performance local/open-source)
    ('bge-m3', 'BAAI/bge-m3', 1024, 'local', '{"max_tokens": 8192, "multilingual": true, "dense_sparse_colbert": true}'),
    ('bge-large-en-v1.5', 'BAAI/bge-large-en-v1.5', 1024, 'local', '{"max_tokens": 512, "multilingual": false}'),
    ('bge-small-en-v1.5', 'BAAI/bge-small-en-v1.5', 384, 'local', '{"max_tokens": 512, "multilingual": false}'),

    -- Nomic AI
    ('nomic-embed-v1.5', 'nomic-ai/nomic-embed-text-v1.5', 768, 'local', '{"max_tokens": 8192, "multilingual": false, "matryoshka_support": true}'),

    -- Alibaba (GTE)
    ('gte-large-en-v1.5', 'Alibaba-NLP/gte-large-en-v1.5', 1024, 'local', '{"max_tokens": 8192, "multilingual": false}'),
    ('gte-qwen2-7b', 'Alibaba-NLP/gte-Qwen2-7B-instruct', 3584, 'local', '{"max_tokens": 32768, "multilingual": true, "requires_gpu": true}'),

    -- Microsoft (E5)
    ('e5-large-multi', 'intfloat/multilingual-e5-large', 1024, 'local', '{"max_tokens": 512, "multilingual": true}'),
    ('e5-large-en', 'intfloat/e5-large-v2', 1024, 'local', '{"max_tokens": 512, "multilingual": false}'),

    -- Mixedbread
    ('mxbai-large-v1', 'mixedbread-ai/mxbai-embed-large-v1', 1024, 'local', '{"max_tokens": 512, "multilingual": false}'),

    -- Jina AI
    ('jina-v3', 'jinaai/jina-embeddings-v3', 1024, 'local', '{"max_tokens": 8192, "multilingual": true, "lora_task_adapters": true}'),

    -- Snowflake
    ('arctic-embed-l', 'Snowflake/snowflake-arctic-embed-l-v2.0', 1024, 'local', '{"max_tokens": 8192, "multilingual": false}'),

    -- Nvidia
    ('nv-embed-v2', 'nvidia/NV-Embed-v2', 3264, 'local', '{"max_tokens": 32768, "multilingual": false, "requires_gpu": true}'),

    -- Sentence Transformers (Classic lightweight baseline)
    ('minilm-l6', 'sentence-transformers/all-MiniLM-L6-v2', 384, 'local', '{"max_tokens": 256, "multilingual": false}')
ON CONFLICT (model_key) DO UPDATE SET
    model_name = EXCLUDED.model_name,
    embedding_dim = EXCLUDED.embedding_dim,
    provider = EXCLUDED.provider,
    metadata = EXCLUDED.metadata,
    updated_at = NOW();