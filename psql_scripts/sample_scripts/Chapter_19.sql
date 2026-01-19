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

CREATE OR REPLACE FUNCTION embeddings.enqueue_embedding_job(p_entity_type text, p_entity_id int)
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
  PERFORM embeddings.enqueue_embedding_job('category', NEW.id);
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
  PERFORM embeddings.enqueue_embedding_job('brand', NEW.id);
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
  PERFORM embeddings.enqueue_embedding_job('product', NEW.id);
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
  PERFORM embeddings.enqueue_embedding_job('variant', NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enqueue_variant_embedding ON product.product_variant;

CREATE TRIGGER enqueue_variant_embedding
AFTER INSERT OR UPDATE OF attributes
ON product.product_variant
FOR EACH ROW
EXECUTE FUNCTION embeddings.trg_enqueue_variant_embedding();

CREATE OR REPLACE FUNCTION embeddings.process_embedding_jobs(p_batch_size int DEFAULT 50)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
  j RECORD;
  processed int := 0;
  input_text text;
  vec vector(1536);
BEGIN
  FOR j IN
    SELECT *
    FROM embeddings.embedding_job
    WHERE status = 'pending'
    ORDER BY created_at
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      -- Mark running
      UPDATE embeddings.embedding_job
      SET status = 'running',
          attempts = attempts + 1,
          updated_at = now(),
          last_error = NULL
      WHERE id = j.id;

      -- Build the input text + write to the correct embedding table
      IF j.entity_type = 'category' THEN

        SELECT coalesce(label,'') || ' ' || coalesce(description,'')
        INTO input_text
        FROM product.category
        WHERE id = j.entity_id;

        vec := api.openai_embed(input_text)::vector(1536);

        INSERT INTO embeddings.product_category_embedding(product_category_id, embedding)
        VALUES (j.entity_id, vec)
        ON CONFLICT (product_category_id)
        DO UPDATE SET embedding = EXCLUDED.embedding;

      ELSIF j.entity_type = 'brand' THEN

        SELECT coalesce(label,'') || ' ' || coalesce(description,'')
        INTO input_text
        FROM product.brand
        WHERE id = j.entity_id;

        vec := api.openai_embed(input_text)::vector(1536);

        INSERT INTO embeddings.product_brand_embedding(product_brand_id, embedding)
        VALUES (j.entity_id, vec)
        ON CONFLICT (product_brand_id)
        DO UPDATE SET embedding = EXCLUDED.embedding;

      ELSIF j.entity_type = 'product' THEN

        SELECT
          coalesce(p.label,'') || ' ' ||
          coalesce(b.label,'') || ' ' ||
          coalesce(c.label,'') || ' ' ||
          coalesce(p.shortdescription,'') || ' ' ||
          coalesce(p.longdescription,'')
        INTO input_text
        FROM product.product p
        JOIN product.brand b ON b.id = p.brand_id
        JOIN product.category c ON c.id = p.category_id
        WHERE p.id = j.entity_id;

        vec := api.openai_embed(input_text)::vector(1536);

        INSERT INTO embeddings.product_embedding(product_id, embedding)
        VALUES (j.entity_id, vec)
        ON CONFLICT (product_id)
        DO UPDATE SET embedding = EXCLUDED.embedding;

      ELSIF j.entity_type = 'variant' THEN

        SELECT coalesce(attributes::text,'')
        INTO input_text
        FROM product.product_variant
        WHERE id = j.entity_id;

        vec := api.openai_embed(input_text)::vector(1536);

        INSERT INTO embeddings.product_variant_embedding(product_variant_id, embedding)
        VALUES (j.entity_id, vec)
        ON CONFLICT (product_variant_id)
        DO UPDATE SET embedding = EXCLUDED.embedding;

      ELSE
        RAISE EXCEPTION 'Unknown entity_type: %', j.entity_type;
      END IF;

      -- Mark done
      UPDATE embeddings.embedding_job
      SET status = 'done',
          updated_at = now()
      WHERE id = j.id;

      processed := processed + 1;

    EXCEPTION WHEN OTHERS THEN
      -- Mark failed but keep the job for retry/inspection
      UPDATE embeddings.embedding_job
      SET status = 'failed',
          last_error = SQLERRM,
          updated_at = now()
      WHERE id = j.id;
    END;
  END LOOP;

  RETURN processed;
END;
$$;

SELECT embeddings.process_embedding_jobs(50);

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


CREATE OR REPLACE FUNCTION api.sql_from_question(p_question text, p_row_limit int DEFAULT 20)
RETURNS text
LANGUAGE plpython3u
AS $$
import json, ssl, urllib.request

rv = plpy.execute("SELECT current_setting('api.openai_api_key', true) AS k")
api_key = rv[0]["k"] if rv and rv[0]["k"] is not None else None
if not api_key:
    raise Exception("OpenAI API key not set.")

SYSTEM = f"""
You are a PostgreSQL SQL generator for an e-commerce schema.
Return ONLY SQL (no markdown, no explanation, no semicolons).
Hard rules:
- SELECT or WITH only.
- Must include LIMIT {p_row_limit}.
- Use only schemas: product, embeddings, api.
- MUST use the provided query vector in the SQL using pgvector cosine distance (<->).
- Prefer current price only:
  JOIN product.product_variant_price pvp ON pvp.product_variant_id = pv.id AND pvp.current = true

Core tables:
- product.product p (id, category_id, brand_id, label, shortdescription, longdescription, image_filename)
- product.category c (id, label, description)
- product.brand b (id, label, description)
- product.product_variant pv (id, product_id, attributes jsonb)
- variants: product.product_variant pv (id, product_id, attributes JSONB)
- price: product.product_variant_price pvp (product_variant_id, price, validity, current)

Embeddings tables (pick the best match for the question):
- embeddings.product_embedding pe (product_id, embedding vector(1536)) join pe.product_id = p.id
- embeddings.product_variant_embedding pve (product_variant_id, embedding vector(1536)) join pve.product_variant_id = pv.id
- embeddings.product_brand_embedding pbe (product_brand_id, embedding vector(1536)) join pbe.product_brand_id = b.id
- embeddings.product_category_embedding pce (product_category_id, embedding vector(1536)) join pce.product_category_id = c.id

Output columns should be useful:
- product id + label
- category label
- brand label when relevant
- price (from current price join when variant is used)
- pv.attributes when relevant
- distance as "distance"
Order by distance ASC.
Use the following code to get the query embedding vector:
  api.openai_embed('{p_question}')::vector(1536)
""".strip()

USER = f"Question: {p_question}"

payload = {
  "model": "gpt-4o-mini",
  "messages": [
    {"role":"system","content":SYSTEM},
    {"role":"user","content":USER}
  ],
  "temperature": 0.0,
  "max_tokens": 250
}

headers = {"Content-Type":"application/json","Authorization":f"Bearer {api_key}"}
ctx = ssl.create_default_context()
req = urllib.request.Request("https://api.openai.com/v1/chat/completions",
                             data=json.dumps(payload).encode("utf-8"),
                             headers=headers)
with urllib.request.urlopen(req, context=ctx) as resp:
    data = json.loads(resp.read().decode("utf-8"))
sql = data["choices"][0]["message"]["content"].strip()

# Defensive cleanup: remove trailing semicolons if model slips
sql = sql.replace(";", "")
return sql
$$;