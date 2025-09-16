-- =============================================================================
-- pgvector + OpenAI + Sample Catalog + Pairing + NL->SQL (Public schema)
-- AI Database (aidb) for E-commerce Embedding and Search
-- =============================================================================

-- Switch connection to the aidb database
\c aidb

\echo '--> Successfully connected to database: aidb'

-- --- Prereqs ---------------------------------------------------------------
\echo '--> Creating extensions...'
CREATE EXTENSION IF NOT EXISTS vector;       -- pgvector
CREATE EXTENSION IF NOT EXISTS plpython3u;   -- demo only (untrusted; needs superuser)

\echo '--> Creating api schema...'
CREATE SCHEMA IF NOT EXISTS api;

\echo '--> Setting search path...'
ALTER DATABASE aidb SET SEARCH_PATH TO api, public;
SET SEARCH_PATH TO api, public;

-- --- Minimal public schema -------------------------------------------------
\echo '--> Creating product reference tables with embeddings...'

CREATE TABLE IF NOT EXISTS public.product_category (
    id   serial PRIMARY KEY,
    name text UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS public.product_brand (
    id   serial PRIMARY KEY,
    name text UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS public.product (
    id          serial PRIMARY KEY,
    name        text NOT NULL,
    description text,
    category_id int REFERENCES public.product_category(id),
    brand_id    int REFERENCES public.product_brand(id),
    embedding   vector(1536)  -- pgvector column
);

CREATE TABLE IF NOT EXISTS public.product_variant (
    id         serial PRIMARY KEY,
    product_id int REFERENCES public.product(id),
    sku        text UNIQUE,
    color      text,
    size       text
);

CREATE TABLE IF NOT EXISTS public.product_variant_price (
    id                 serial PRIMARY KEY,
    product_variant_id int REFERENCES public.product_variant(id),
    currency           text NOT NULL DEFAULT 'USD',
    amount             numeric(10,2) NOT NULL
);

-- Helpful unique constraints for idempotent upserts
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_product_category_name') THEN
        ALTER TABLE public.product_category ADD CONSTRAINT uq_product_category_name UNIQUE (name);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_product_brand_name') THEN
        ALTER TABLE public.product_brand ADD CONSTRAINT uq_product_brand_name UNIQUE (name);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_product_name') THEN
        ALTER TABLE public.product ADD CONSTRAINT uq_product_name UNIQUE (name);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_product_variant_sku') THEN
        ALTER TABLE public.product_variant ADD CONSTRAINT uq_product_variant_sku UNIQUE (sku);
    END IF;
END $$;

-- --- Sample data (guaranteed matches for women's black jeans < $100) -------
\echo '--> Inserting sample data...'

INSERT INTO public.product_category(name) VALUES
  ('Shirt'),('T-Shirt'),('Blouse'),('Sweater'),
  ('Jeans'),('Trousers'),('Skirt'),('Shorts')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.product_brand(name) VALUES
  ('Urban Style'), ('Acme Apparel'), ('Classic Wear')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.product(name, description, category_id, brand_id) VALUES
  ('Women''s Black Skinny Jeans', 'Stretch denim skinny fit',
     (SELECT id FROM public.product_category WHERE name='Jeans'),
     (SELECT id FROM public.product_brand    WHERE name='Urban Style')),
  ('Women''s Black Straight Jeans', 'Classic straight-leg black jeans',
     (SELECT id FROM public.product_category WHERE name='Jeans'),
     (SELECT id FROM public.product_brand    WHERE name='Urban Style')),
  ('Linen Breeze Shirt', 'Lightweight linen shirt, perfect for summer',
     (SELECT id FROM public.product_category WHERE name='Shirt'),
     (SELECT id FROM public.product_brand    WHERE name='Acme Apparel')),
  ('Classic Cotton T-Shirt', 'White cotton tee for everyday wear',
     (SELECT id FROM public.product_category WHERE name='T-Shirt'),
     (SELECT id FROM public.product_brand    WHERE name='Classic Wear')),
  ('Pleated Skirt', 'Casual pleated skirt',
     (SELECT id FROM public.product_category WHERE name='Skirt'),
     (SELECT id FROM public.product_brand    WHERE name='Urban Style'))
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.product_variant(product_id, sku, color, size) VALUES
  ((SELECT id FROM public.product WHERE name='Women''s Black Skinny Jeans'),   'SKU-JEANS-WSK-BLK-28', 'black', '28'),
  ((SELECT id FROM public.product WHERE name='Women''s Black Skinny Jeans'),   'SKU-JEANS-WSK-BLK-30', 'black', '30'),
  ((SELECT id FROM public.product WHERE name='Women''s Black Straight Jeans'), 'SKU-JEANS-WST-BLK-30', 'black', '30'),
  ((SELECT id FROM public.product WHERE name='Linen Breeze Shirt'), 'SKU-SHIRT-001', 'blue', 'M'),
  ((SELECT id FROM public.product WHERE name='Classic Cotton T-Shirt'), 'SKU-TS-001', 'white', 'L'),
  ((SELECT id FROM public.product WHERE name='Pleated Skirt'), 'SKU-SKIRT-001', 'red', 'S')
ON CONFLICT (sku) DO NOTHING;

INSERT INTO public.product_variant_price(product_variant_id, currency, amount) VALUES
  ((SELECT id FROM public.product_variant WHERE sku='SKU-JEANS-WSK-BLK-28'), 'USD', 39.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-JEANS-WSK-BLK-30'), 'USD', 44.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-JEANS-WST-BLK-30'), 'USD', 34.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-SHIRT-001'), 'USD', 49.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-TS-001'),    'USD', 19.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-SKIRT-001'), 'USD', 29.99)
ON CONFLICT DO NOTHING;

-- --- Complements map -------------------------------------------------------
\echo '--> Creating category complements mapping...'

CREATE TABLE IF NOT EXISTS api.category_complements (
  category_name text PRIMARY KEY,
  complements   text[] NOT NULL
);

INSERT INTO api.category_complements(category_name, complements) VALUES
  ('Shirt',     ARRAY['Jeans','Trousers','Skirt','Shorts']),
  ('T-Shirt',   ARRAY['Jeans','Trousers','Skirt','Shorts']),
  ('Blouse',    ARRAY['Skirt','Trousers','Jeans']),
  ('Sweater',   ARRAY['Jeans','Trousers','Skirt']),
  ('Jeans',     ARRAY['Shirt','T-Shirt','Blouse','Sweater']),
  ('Trousers',  ARRAY['Shirt','T-Shirt','Blouse','Sweater']),
  ('Skirt',     ARRAY['Shirt','Blouse','Sweater']),
  ('Shorts',    ARRAY['T-Shirt','Shirt'])
ON CONFLICT (category_name) DO NOTHING;

-- --- Embedding helpers (OpenAI) -------------------------------------------
\echo '--> Creating OpenAI embedding functions...'

-- Store API key/org in session-scoped DB GUCs:
--   SELECT set_config('api.openai_api_key','sk-...YOUR_KEY...', false);
--   SELECT set_config('api.openai_organization','org_...optional...', false);

-- Single-text embedding with retries/backoff
CREATE OR REPLACE FUNCTION api.openai_embed(input_text text)
RETURNS float4[]
LANGUAGE plpython3u
AS $$
import json, ssl, time, random, urllib.request, urllib.error
def call_openai(payload, api_key, org):
    req = urllib.request.Request(
        "https://api.openai.com/v1/embeddings",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            **({"OpenAI-Organization": org} if org else {})
        }
    )
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))

rv = plpy.execute("SELECT current_setting('api.openai_api_key', true) AS k, current_setting('api.openai_organization', true) AS o")
api_key = rv[0]["k"] if rv and rv[0]["k"] is not None else None
org     = rv[0]["o"] if rv and rv[0]["o"] is not None else None
if not api_key:
    raise Exception("OpenAI API key not set. Use: SELECT set_config('api.openai_api_key','sk-...','f');")

payload = {"model":"text-embedding-3-small","input": input_text or ""}

attempts = 6
for i in range(attempts):
    try:
        data = call_openai(payload, api_key, org)
        emb = data["data"][0]["embedding"]
        return [float(x) for x in emb]
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        if e.code not in (429, 500, 502, 503, 504) or i == attempts - 1:
            raise Exception(f"OpenAI HTTP {e.code}. Body: {body[:400]} ...")
        time.sleep((2 ** i) * 0.5 + random.uniform(0, 0.3))
    except Exception as e:
        if i == attempts - 1:
            raise
        time.sleep((2 ** i) * 0.5 + random.uniform(0, 0.2))
$$;

-- Batch embeddings (array of texts)
CREATE OR REPLACE FUNCTION api.openai_embed_batch(inputs text[])
RETURNS float4[][]
LANGUAGE plpython3u
AS $$
import json, ssl, time, random, urllib.request, urllib.error
def call_openai(payload, api_key, org):
    req = urllib.request.Request(
        "https://api.openai.com/v1/embeddings",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            **({"OpenAI-Organization": org} if org else {})
        }
    )
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
        return json.loads(resp.read().decode("utf-8"))

rv = plpy.execute("SELECT current_setting('api.openai_api_key', true) AS k, current_setting('api.openai_organization', true) AS o")
api_key = rv[0]["k"] if rv and rv[0]["k"] is not None else None
org     = rv[0]["o"] if rv and rv[0]["o"] is not None else None
if not api_key:
    raise Exception("OpenAI API key not set. Use: SELECT set_config('api.openai_api_key','sk-...','f');")

items = [i if i is not None else "" for i in (inputs or [])]
if not items:
    return []

payload = {"model":"text-embedding-3-small","input": items}

attempts = 6
for i in range(attempts):
    try:
        data = call_openai(payload, api_key, org)
        out = []
        for d in data["data"]:
            out.append([float(x) for x in d["embedding"]])
        return out
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        if e.code not in (429, 500, 502, 503, 504) or i == attempts - 1:
            raise Exception(f"OpenAI HTTP {e.code}. Body: {body[:400]} ...")
        time.sleep((2 ** i) * 0.5 + random.uniform(0, 0.3))
    except Exception as e:
        if i == attempts - 1:
            raise
        time.sleep((2 ** i) * 0.5 + random.uniform(0, 0.2))
$$;

-- Create vector index for embeddings
\echo '--> Creating vector index for embeddings...'
CREATE INDEX IF NOT EXISTS product_embedding_ivfflat_idx
  ON public.product USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
ANALYZE public.product;

-- Embed products in small batches using batch API
-- SIMPLE & RELIABLE: per-row embedding (no array gymnastics)
CREATE OR REPLACE FUNCTION api.embed_products(batch_size int DEFAULT 200)
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    done_count int := 0;
BEGIN
    FOR r IN
        SELECT p.id, p.name, p.description,
               pc.name AS category_name,
               pb.name AS brand_name
        FROM public.product p
        LEFT JOIN public.product_category pc ON pc.id = p.category_id
        LEFT JOIN public.product_brand    pb ON pb.id = p.brand_id
        WHERE p.embedding IS NULL
        ORDER BY p.id
        LIMIT batch_size
    LOOP
        BEGIN
            UPDATE public.product
               SET embedding = api.openai_embed(
                    coalesce(r.name,'') || ' ' ||
                    coalesce(r.brand_name,'') || ' ' ||
                    coalesce(r.category_name,'') || ' ' ||
                    coalesce(r.description,'')
               )::vector(1536)
             WHERE id = r.id;
            done_count := done_count + 1;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Failed to embed product id %: %', r.id, SQLERRM;
        END;
    END LOOP;

    RETURN done_count;
END;
$$;

COMMENT ON FUNCTION api.embed_products(int) IS 'Embeds up to batch_size products lacking vectors; returns count updated.';

-- --- Pairing view (item->item within complementary categories) ------------
\echo '--> Creating product pairing view...'

CREATE OR REPLACE VIEW api.product_pairs_demo AS
SELECT
  p1.id   AS base_product_id,
  p1.name AS base_name,
  c1.name AS base_category,
  p2.id   AS candidate_product_id,
  p2.name AS candidate_name,
  c2.name AS candidate_category,
  (p1.embedding <=> p2.embedding) AS cosine_distance
FROM public.product p1
JOIN public.product_category c1 ON c1.id = p1.category_id
JOIN api.category_complements cc ON cc.category_name = c1.name
JOIN public.product p2 ON p2.id <> p1.id
JOIN public.product_category c2 ON c2.id = p2.category_id
WHERE c2.name = ANY (cc.complements)
  AND p1.embedding IS NOT NULL
  AND p2.embedding IS NOT NULL;

-- --- Similar-items (query embedding once; returns double precision) --------
\echo '--> Creating similar items search function...'

CREATE OR REPLACE FUNCTION api.similar_items(query_text text, k int DEFAULT 10)
RETURNS TABLE(product_id int, name text, category text, price numeric, distance double precision)
LANGUAGE plpgsql
AS $$
DECLARE
    qvec vector(1536);
BEGIN
    SELECT api.openai_embed(query_text)::vector(1536) INTO qvec;
    RETURN QUERY
    WITH RES AS MATERIALIZED (
      SELECT
          p.id                    AS product_id,
          p.name                  AS name,
          c.name                  AS category,
          pvp.amount              AS price,
          ( qvec  <=> p.embedding)  AS distance
      FROM public.product p
      JOIN public.product_category c ON c.id = p.category_id
      JOIN public.product_variant pv ON pv.product_id = p.id
      JOIN public.product_variant_price pvp ON pvp.product_variant_id = pv.id
      WHERE p.embedding IS NOT NULL
    ORDER BY p.embedding <=> qvec)
    SELECT * FROM RES
    LIMIT k;
END;
$$;

-- Answer a question using OpenAI - Humanize results with OpenAI
\echo '--> Creating OpenAI chat response function...'

CREATE OR REPLACE FUNCTION api.answer_with_openai(p_question text, p_rows jsonb)
RETURNS text
LANGUAGE plpython3u
AS $$
import json, ssl, urllib.request

rows = json.dumps(p_rows)

rv = plpy.execute("SELECT current_setting('api.openai_api_key', true) AS k")
api_key = rv[0]["k"] if rv and rv[0]["k"] is not None else None
if not api_key:
    raise Exception("OpenAI API key not set.")

SYSTEM = """You are a helpful assistant.
Take the user question and the SQL rows returned, and write a clear, human reply.
- Mention the question.
- Summarize how many results were found.
- List items with their name, price if present, and category.
- Do not invent anything beyond rows JSON.
PUBLIC schema tables/columns:
- public.product(id, name, description, category_id, brand_id, embedding)
- public.product_category(id, name)
- public.product_brand(id, name)
- public.product_variant(id, product_id, sku, color, size)
- public.product_variant_price(id, product_variant_id, currency, amount)
- api.category_complements(category_name, complements)

Rules:
- Categories are broad: product_category.name values like 'Jeans', 'Shirt', 'Skirt'.
- Gender words (women, men, kids) appear in product.name, NOT in category.
- Price: product_variant_price.amount (alias pvp).
- Color/size: product_variant.color / size (alias pv).
- Category: product_category.name (alias pc). Join pc ON pc.id = p.category_id.
- To use price/color: JOIN product_variant pv ON pv.product_id = p.id
  AND JOIN product_variant_price pvp ON pvp.product_variant_id = pv.id.
- Use LOWER() for case-insensitive filters, e.g. LOWER(p.name) LIKE '%women%'.
- Only SELECT. No semicolons. Always LIMIT {row_limit}.
- Prefer clear aliases (product_name, price).
- If no rows are returned just respond.
"""

USER = f"Question: {p_question}\n\nRows: {rows}"

payload = {
  "model": "gpt-4o-mini",
  "messages": [
    {"role":"system","content":SYSTEM},
    {"role":"user","content":USER}
  ],
  "temperature": 0.2,
  "max_tokens": 500
}

headers = {"Content-Type":"application/json","Authorization":f"Bearer {api_key}"}
ctx = ssl.create_default_context()
req = urllib.request.Request("https://api.openai.com/v1/chat/completions",
                             data=json.dumps(payload).encode("utf-8"),
                             headers=headers)
with urllib.request.urlopen(req, context=ctx) as resp:
    data = json.loads(resp.read().decode("utf-8"))
return data["choices"][0]["message"]["content"].strip()
$$;

-- Answer a question using OpenAI - Humanize results with OpenAI and returns results
\echo '--> Creating chat interface function...'

CREATE OR REPLACE FUNCTION api.chat(p_question text, k int DEFAULT 10)
RETURNS TABLE(assistant_text text, rows jsonb)
LANGUAGE plpgsql
AS $$
DECLARE
  data jsonb;
BEGIN
  SELECT jsonb_agg(t) INTO data
  FROM (
    SELECT s.product_id, s.name, s.category, s.distance
    FROM api.similar_items(p_question, k) s
  ) t;

  assistant_text := api.answer_with_openai(p_question, data);
  rows := coalesce(data, '[]'::jsonb);

  RETURN NEXT;
END;
$$;

\echo '--> AI database setup completed successfully!'

/*
 =============================================================================
 Quick use
 =============================================================================
 1) Set your API key (session-only):
    SELECT set_config('api.openai_api_key','sk-...YOUR_KEY...', false);

 2) Create some embeddings (run a few times if you have more rows):
    SELECT api.embed_products(25);

 3) Similar-items demo using embeddings:
    SELECT * FROM api.similar_items('blue casual summer shirt for men', 2);

 4) Chat with the assistant:
    SELECT * FROM api.chat('What are some similar items?', 2);
    SELECT * FROM api.chat('looking for a casual blue summer shirt', 5);
    SELECT * FROM api.chat('Tell me about women''s black jeans', 3);
    SELECT * FROM api.chat('What are the best jeans for men?', 4);
 =============================================================================
*/