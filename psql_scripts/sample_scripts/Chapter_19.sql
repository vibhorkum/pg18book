/* ============================================================================

                        Code samples for Chapter 19 
    - to be run in AIDB
                      

============================================================================ */ 



CREATE EXTENSION IF NOT EXISTS pg_background;


CREATE TABLE IF NOT EXISTS embeddings.embedding_job (
  id            bigserial PRIMARY KEY,
  entity_type   text NOT NULL CHECK (entity_type IN ('category','brand','product','variant')),
  entity_id     integer NOT NULL,
  status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','running','done','failed')),
  attempts      int  NOT NULL DEFAULT 0,
  last_error    text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);


CREATE INDEX IF NOT EXISTS embedding_job_pending_idx
  ON embeddings.embedding_job (status, created_at);

CREATE INDEX IF NOT EXISTS embedding_job_entity_idx
  ON embeddings.embedding_job (entity_type, entity_id);

CREATE OR REPLACE FUNCTION embeddings.sf_enqueue_embedding_job(p_entity_type text, p_entity_id int)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Avoid enqueuing duplicates when multiple updates happen quickly.
  -- If a job is already pending/running for that entity, we do nothing.
  IF EXISTS (
    SELECT 1
    FROM embeddings.embedding_job
    WHERE entity_type = p_entity_type
      AND entity_id   = p_entity_id
      AND status IN ('pending','running')
  ) THEN
    RETURN;
  END IF;

  INSERT INTO embeddings.embedding_job(entity_type, entity_id)
  VALUES (p_entity_type, p_entity_id);
END;
$$;

CREATE OR REPLACE FUNCTION embeddings.trg_enqueue_category_embedding()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM embeddings.sf_enqueue_embedding_job('category', NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enqueue_category_embedding ON product.category;

CREATE TRIGGER enqueue_category_embedding
AFTER INSERT OR UPDATE OF label, description
ON product.category
FOR EACH ROW
EXECUTE FUNCTION embeddings.trg_enqueue_category_embedding();

CREATE OR REPLACE FUNCTION embeddings.trg_enqueue_brand_embedding()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM embeddings.sf_enqueue_embedding_job('brand', NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enqueue_brand_embedding ON product.brand;

CREATE TRIGGER enqueue_brand_embedding
AFTER INSERT OR UPDATE OF label, description
ON product.brand
FOR EACH ROW
EXECUTE FUNCTION embeddings.trg_enqueue_brand_embedding();

CREATE OR REPLACE FUNCTION embeddings.trg_enqueue_product_embedding()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM embeddings.sf_enqueue_embedding_job('product', NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enqueue_product_embedding ON product.product;

CREATE TRIGGER enqueue_product_embedding
AFTER INSERT OR UPDATE OF label, shortdescription, longdescription, category_id, brand_id
ON product.product
FOR EACH ROW
EXECUTE FUNCTION embeddings.trg_enqueue_product_embedding();

CREATE OR REPLACE FUNCTION embeddings.trg_enqueue_variant_embedding()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM embeddings.sf_enqueue_embedding_job('variant', NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enqueue_variant_embedding ON product.product_variant;

CREATE TRIGGER enqueue_variant_embedding
AFTER INSERT OR UPDATE OF attributes
ON product.product_variant
FOR EACH ROW
EXECUTE FUNCTION embeddings.trg_enqueue_variant_embedding();

CREATE OR REPLACE FUNCTION embeddings.sf_process_embedding_jobs(
  p_batch_size integer DEFAULT 50
)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, embeddings, product, api
AS $function$
DECLARE
  v_job        embeddings.embedding_job%ROWTYPE;
  v_processed  integer := 0;
  v_input_text text;
  v_vec        vector(1536);
BEGIN
  FOR v_job IN
    SELECT ej.*
    FROM embeddings.embedding_job ej
    WHERE ej.status = 'pending'
    ORDER BY ej.created_at
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      -- Mark running
      UPDATE embeddings.embedding_job ej
      SET status     = 'running',
          attempts   = ej.attempts + 1,
          updated_at = now(),
          last_error = NULL
      WHERE ej.id = v_job.id;

      -- Build input text and upsert the embedding into the correct table.
      IF v_job.entity_type = 'category' THEN
        SELECT coalesce(c.label, '') || ' ' || coalesce(c.description, '')
        INTO v_input_text
        FROM product.category c
        WHERE c.id = v_job.entity_id;

        v_vec := api.openai_embed(v_input_text)::vector(1536);

        INSERT INTO embeddings.product_category_embedding (product_category_id, embedding)
        VALUES (v_job.entity_id, v_vec)
        ON CONFLICT (product_category_id)
        DO UPDATE
          SET embedding = EXCLUDED.embedding;

      ELSIF v_job.entity_type = 'brand' THEN
        SELECT coalesce(b.label, '') || ' ' || coalesce(b.description, '')
        INTO v_input_text
        FROM product.brand b
        WHERE b.id = v_job.entity_id;

        v_vec := api.openai_embed(v_input_text)::vector(1536);

        INSERT INTO embeddings.product_brand_embedding (product_brand_id, embedding)
        VALUES (v_job.entity_id, v_vec)
        ON CONFLICT (product_brand_id)
        DO UPDATE
          SET embedding = EXCLUDED.embedding;

      ELSIF v_job.entity_type = 'product' THEN
        SELECT
          coalesce(p.label, '') || ' ' ||
          coalesce(b.label, '') || ' ' ||
          coalesce(c.label, '') || ' ' ||
          coalesce(p.shortdescription, '') || ' ' ||
          coalesce(p.longdescription, '')
        INTO v_input_text
        FROM product.product p
        JOIN product.brand b
          ON b.id = p.brand_id
        JOIN product.category c
          ON c.id = p.category_id
        WHERE p.id = v_job.entity_id;

        v_vec := api.sf_openai_embed(v_input_text)::vector(1536);

        INSERT INTO embeddings.product_embedding (product_id, embedding)
        VALUES (v_job.entity_id, v_vec)
        ON CONFLICT (product_id)
        DO UPDATE
          SET embedding = EXCLUDED.embedding;

      ELSIF v_job.entity_type = 'variant' THEN
        SELECT coalesce(v.attributes::text, '')
        INTO v_input_text
        FROM product.product_variant v
        WHERE v.id = v_job.entity_id;

        v_vec := api.openai_embed(v_input_text)::vector(1536);

        INSERT INTO embeddings.product_variant_embedding (product_variant_id, embedding)
        VALUES (v_job.entity_id, v_vec)
        ON CONFLICT (product_variant_id)
        DO UPDATE
          SET embedding = EXCLUDED.embedding;

      ELSE
        RAISE EXCEPTION 'Unknown entity_type: %', v_job.entity_type
          USING ERRCODE = '22023';
      END IF;

      -- Mark done
      UPDATE embeddings.embedding_job ej
      SET status     = 'done',
          updated_at = now()
      WHERE ej.id = v_job.id;

      v_processed := v_processed + 1;

    EXCEPTION WHEN OTHERS THEN
      -- Mark failed but keep the job for retry/inspection
      UPDATE embeddings.embedding_job ej
      SET status     = 'failed',
          last_error = SQLERRM,
          updated_at = now()
      WHERE ej.id = v_job.id;
    END;
  END LOOP;

  RETURN v_processed;
END;
$function$;

COMMENT ON FUNCTION embeddings.sf_process_embedding_jobs(integer)
IS 'Process pending embedding jobs in batches; generates embeddings and upserts into per-entity embedding tables.';


SELECT embeddings.sf_process_embedding_jobs(50);

SELECT * FROM embeddings.embedding_job WHERE status = 'pending' ORDER BY created_at;

SELECT id, entity_type, entity_id, attempts, last_error
FROM embeddings.embedding_job
WHERE status = 'failed'
ORDER BY updated_at DESC;

ALTER TABLE embeddings.embedding_job
ADD COLUMN IF NOT EXISTS next_run_at timestamptz NOT NULL DEFAULT now(),
ADD COLUMN IF NOT EXISTS max_attempts int NOT NULL DEFAULT 10;

CREATE INDEX IF NOT EXISTS embedding_job_runnable_idx
  ON embeddings.embedding_job (status, next_run_at, created_at);

ALTER TABLE embeddings.product_category_embedding
ADD COLUMN IF NOT EXISTS content_hash text;

ALTER TABLE embeddings.product_brand_embedding
ADD COLUMN IF NOT EXISTS content_hash text;

ALTER TABLE embeddings.product_embedding
ADD COLUMN IF NOT EXISTS content_hash text;

ALTER TABLE embeddings.product_variant_embedding
ADD COLUMN IF NOT EXISTS content_hash text;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE embeddings.embedding_job
ADD COLUMN IF NOT EXISTS next_run_at timestamptz NOT NULL DEFAULT now(),
ADD COLUMN IF NOT EXISTS max_attempts int NOT NULL DEFAULT 10;

CREATE INDEX IF NOT EXISTS embedding_job_runnable_idx
  ON embeddings.embedding_job (status, next_run_at, created_at);

ALTER TABLE embeddings.embedding_job
ADD COLUMN IF NOT EXISTS next_run_at timestamptz NOT NULL DEFAULT now(),
ADD COLUMN IF NOT EXISTS max_attempts int NOT NULL DEFAULT 10;

CREATE INDEX IF NOT EXISTS embedding_job_runnable_idx
  ON embeddings.embedding_job (status, next_run_at, created_at);

ALTER TABLE embeddings.product_category_embedding ADD COLUMN IF NOT EXISTS content_hash text;
ALTER TABLE embeddings.product_brand_embedding    ADD COLUMN IF NOT EXISTS content_hash text;
ALTER TABLE embeddings.product_embedding          ADD COLUMN IF NOT EXISTS content_hash text;
ALTER TABLE embeddings.product_variant_embedding  ADD COLUMN IF NOT EXISTS content_hash text;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

WITH q AS (
  SELECT api.openai_embed($1)::vector(1536) AS qvec
)
SELECT p.id, p.label, (pe.embedding <=> q.qvec) AS distance
FROM product.product p
JOIN embeddings.product_embedding pe ON pe.product_id = p.id
CROSS JOIN q
ORDER BY pe.embedding <=> q.qvec
LIMIT 10;

CREATE TABLE IF NOT EXISTS embeddings.query_embedding_cache (
  query_text     text PRIMARY KEY,
  embedding      vector(1536) NOT NULL,
  model_id       text NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  last_used_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS query_embedding_cache_last_used_idx
  ON embeddings.query_embedding_cache (last_used_at);

CREATE OR REPLACE FUNCTION embeddings.sf_get_query_embedding(
  p_query    text,
  p_model_id text DEFAULT 'text-embedding-3-small'
)
RETURNS vector(1536)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, embeddings, api
AS $function$
DECLARE
  v_embedding vector(1536);
BEGIN
  -- Fast path: cache hit
  SELECT qec.embedding
  INTO v_embedding
  FROM embeddings.query_embedding_cache qec
  WHERE qec.query_text = p_query
    AND qec.model_id    = p_model_id;

  IF v_embedding IS NOT NULL THEN
    UPDATE embeddings.query_embedding_cache qec
    SET last_used_at = now()
    WHERE qec.query_text = p_query
      AND qec.model_id    = p_model_id;

    RETURN v_embedding;
  END IF;

  -- Cache miss: compute embedding
  v_embedding := api.openai_embed(p_query)::vector(1536);

  INSERT INTO embeddings.query_embedding_cache (query_text, embedding, model_id, last_used_at)
  VALUES (p_query, v_embedding, p_model_id, now())
  ON CONFLICT (query_text)
  DO UPDATE
    SET embedding    = EXCLUDED.embedding,
        model_id     = EXCLUDED.model_id,
        last_used_at = now();

  RETURN v_embedding;
END;
$function$;

COMMENT ON FUNCTION embeddings.sf_get_query_embedding(text, text)
IS 'Return (and cache) an embedding for the given query text and model id.';

WITH q AS (
  SELECT embeddings.sf_get_query_embedding($1) AS qvec
)
SELECT p.id, p.label, (pe.embedding <=> q.qvec) AS distance
FROM product.product p
JOIN embeddings.product_embedding pe ON pe.product_id = p.id
CROSS JOIN q
ORDER BY pe.embedding <=> q.qvec
LIMIT 10;

DELETE FROM embeddings.query_embedding_cache
WHERE last_used_at < now() - interval '7 days';

ALTER TABLE embeddings.product_embedding
ADD COLUMN IF NOT EXISTS model_id text NOT NULL DEFAULT 'text-embedding-3-small';

WITH q AS (
  SELECT embeddings.sf_get_query_embedding($1, 'text-embedding-3-small') AS qvec
)
SELECT p.id, p.label, (pe.embedding <=> q.qvec) AS distance
FROM product.product p
JOIN embeddings.product_embedding pe ON pe.product_id = p.id
CROSS JOIN q
WHERE pe.model_id = 'text-embedding-3-small'
ORDER BY pe.embedding <=> q.qvec
LIMIT 10;