/* 
===============================================================================
 FILE: chapter_10.sql
 DESCRIPTION: SQL script file for Chapter 10 - Building an Analytics Schema
    Dimensions:
        - date
        - product
        - customer and localtion
    Facts:
        - sales (at the sales_transaction_line level)


 We will show three approaches
    1. View-only approach (except for the date dimension table and the auxiliairy tables for state and territory)
        - uses vo-analytics schema
    2. Materialized view approach with periodic refresh (same as view-only but with better performance)
        - uses mv-analytics schema
    3. Materialized views with use of IVMM (Incremental View Maintenance)
        - uses ivmm-analytics schema
    4. Table-based appraoach using insert/update/delete triggers to maintain the fact table
        - uses tt-analytics schema
The auxilliary schema contains supporting tables and functions to help build the dimension tables and views

===============================================================================
*/



-- define the analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;  

-- schema that contains additional data used to generate the dimensions
CREATE SCHEMA IF NOT EXISTS auxiliary;

DROP TABLE IF EXISTS auxiliary.us_state CASCADE;
CREATE TABLE auxiliary.us_state (
    state_code CHAR(2) PRIMARY KEY,
    state_name VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL
);

INSERT INTO auxiliary.us_state (state_code, state_name, region) VALUES
    ('AL', 'Alabama', 'South'),
    ('AK', 'Alaska', 'West'),
    ('AZ', 'Arizona', 'West'),
    ('AR', 'Arkansas', 'South'),
    ('CA', 'California', 'West'),
    ('CO', 'Colorado', 'West'),
    ('CT', 'Connecticut', 'Northeast'),
    ('DE', 'Delaware', 'South'),
    ('FL', 'Florida', 'South'),
    ('GA', 'Georgia', 'South'),
    ('HI', 'Hawaii', 'West'),
    ('ID', 'Idaho', 'West'),
    ('IL', 'Illinois', 'Midwest'),
    ('IN', 'Indiana', 'Midwest'),
    ('IA', 'Iowa', 'Midwest'),
    ('KS', 'Kansas', 'Midwest'),
    ('KY', 'Kentucky', 'South'),
    ('LA', 'Louisiana', 'South'),
    ('ME', 'Maine', 'Northeast'),
    ('MD', 'Maryland', 'South'),
    ('MA', 'Massachusetts', 'Northeast'),
    ('MI', 'Michigan', 'Midwest'),
    ('MN', 'Minnesota', 'Midwest'),
    ('MS', 'Mississippi', 'South'),
    ('MO', 'Missouri', 'Midwest'),
    ('MT', 'Montana', 'West'),
    ('NE', 'Nebraska', 'Midwest'),
    ('NV', 'Nevada', 'West'),
    ('NH', 'New Hampshire', 'Northeast'),
    ('NJ', 'New Jersey', 'Northeast'),
    ('NM', 'New Mexico', 'West'),
    ('NY', 'New York', 'Northeast'),
    ('NC', 'North Carolina', 'South'),
    ('ND', 'North Dakota', 'Midwest'),
    ('OH', 'Ohio', 'Midwest'),
    ('OK', 'Oklahoma', 'South'),
    ('OR', 'Oregon', 'West'),
    ('PA', 'Pennsylvania', 'Northeast'),
    ('RI', 'Rhode Island', 'Northeast'),
    ('SC', 'South Carolina', 'South'),
    ('SD', 'South Dakota', 'Midwest'),
    ('TN', 'Tennessee', 'South'),
    ('TX', 'Texas', 'South'),
    ('UT', 'Utah', 'West'),
    ('VT', 'Vermont', 'Northeast'),
    ('VA', 'Virginia', 'South'),
    ('WA', 'Washington', 'West'),
    ('WV', 'West Virginia', 'South'),
    ('WI', 'Wisconsin', 'Midwest'),
    ('WY', 'Wyoming', 'West'),
    ('DC', 'District of Columbia', 'South');


CREATE OR REPLACE FUNCTION auxiliary.parse_state_postalcode(zipcode VARCHAR)
RETURNS CHAR(2) AS $$
DECLARE
    v_state_code CHAR(2);
BEGIN
    v_state_code := SUBSTRING(zipcode, 1, 3);
    -- check if state_code exists in dim_us_state
    IF NOT EXISTS (SELECT 1 FROM auxiliary.us_state WHERE state_code = v_state_code) THEN
        RAISE NOTICE 'Invalid state code in zipcode: %', zipcode;
        v_state_code = 'XX'; -- unknown state code
    END IF;
    RETURN v_state_code;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION auxiliary.parse_zipcode_postalcode(zipcode VARCHAR)
RETURNS CHAR(5) AS $$
BEGIN
    RETURN SUBSTRING(zipcode, 4, 5);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP TABLE IF EXISTS auxiliary.sales_territory CASCADE;
CREATE TABLE auxiliary.sales_territory (
    territory_id INTEGER PRIMARY KEY,
    us_state_code CHAR(2) REFERENCES auxiliary.us_state(state_code),
    territory_name VARCHAR(100) NOT NULL
);

-- Populate auxiliary.sales_territory: assign each state (and DC) to one of five territories.
-- territory_id is unique per row; territory_name groups states into 5 territories.
INSERT INTO auxiliary.sales_territory (territory_id, us_state_code, territory_name) VALUES
    (1, 'ME', 'Northeast'),
    (2, 'NH', 'Northeast'),
    (3, 'VT', 'Northeast'),
    (4, 'MA', 'Northeast'),
    (5, 'RI', 'Northeast'),
    (6, 'CT', 'Northeast'),
    (7, 'NY', 'Northeast'),
    (8, 'NJ', 'Northeast'),
    (9, 'PA', 'Northeast'),

    (10, 'DE', 'Southeast'),
    (11, 'MD', 'Southeast'),
    (12, 'DC', 'Southeast'),
    (13, 'VA', 'Southeast'),
    (14, 'WV', 'Southeast'),
    (15, 'NC', 'Southeast'),
    (16, 'SC', 'Southeast'),
    (17, 'GA', 'Southeast'),
    (18, 'FL', 'Southeast'),
    (19, 'AL', 'Southeast'),
    (20, 'MS', 'Southeast'),
    (21, 'TN', 'Southeast'),
    (22, 'KY', 'Southeast'),

    (23, 'OH', 'Midwest'),
    (24, 'MI', 'Midwest'),
    (25, 'IN', 'Midwest'),
    (26, 'IL', 'Midwest'),
    (27, 'WI', 'Midwest'),
    (28, 'MN', 'Midwest'),
    (29, 'IA', 'Midwest'),
    (30, 'MO', 'Midwest'),
    (31, 'ND', 'Midwest'),
    (32, 'SD', 'Midwest'),
    (33, 'NE', 'Midwest'),
    (34, 'KS', 'Midwest'),

    (35, 'AR', 'Southwest'),
    (36, 'LA', 'Southwest'),
    (37, 'OK', 'Southwest'),
    (38, 'TX', 'Southwest'),
    (39, 'NM', 'Southwest'),
    (40, 'AZ', 'Southwest'),

    (41, 'CA', 'West'),
    (42, 'OR', 'West'),
    (43, 'WA', 'West'),
    (44, 'NV', 'West'),
    (45, 'ID', 'West'),
    (46, 'MT', 'West'),
    (47, 'WY', 'West'),
    (48, 'UT', 'West'),
    (49, 'CO', 'West'),
    (50, 'AK', 'West'),
    (51, 'HI', 'West');

/*
===============================================================================
 vo-analytics SCHEMA: VIEW-ONLY ANALYTICS SCHEMA
    - dimensions
        - dim_vw_date
        - vw_dim_product
        - vw_dim_customer_location
    - facts
        - vw_fact_sales
===============================================================================
*/

-- create the schema for view-only analytics
DROP SCHEMA IF EXISTS vo_analytics CASCADE;
CREATE SCHEMA vo_analytics;


-- create the date dimension view
DROP VIEW IF EXISTS vo_analytics.vw_dim_date CASCADE;

CREATE OR REPLACE VIEW vo_analytics.vw_dim_date AS
SELECT
    d::DATE AS date_key,
    EXTRACT(DAY FROM d) AS day,
    EXTRACT(MONTH FROM d) AS month,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(DOW FROM d) AS day_of_week,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN true ELSE false END AS is_weekend
FROM
    GENERATE_SERIES('2020-01-01'::DATE, '2030-12-31'::DATE, INTERVAL '1 day') AS d;

-- create the product dimension view
DROP VIEW IF EXISTS vo_analytics.vw_dim_product CASCADE;

CREATE OR REPLACE VIEW vo_analytics.vw_dim_product AS
    SELECT 
        pv.id as product_variant_id, attributes, 
        pvp.price as current_price, 
        pv.attributes->>'size' as size, 
        pv.attributes->>'color' as color,
        p.label, c.label AS category, b.label AS brand, 
        co.name AS co_name,
        co.alpha3_code AS co_alpha3_code
    FROM product_variant pv
    JOIN product_variant_price pvp ON pv.id = pvp.product_variant_id AND pvp.current = true
    JOIN product p ON pv.product_id = p.id
    JOIN category c ON p.category_id = c.id
    JOIN brand b ON p.brand_id = b.id
    JOIN country_of_origin co ON co.brand_id = b.id;

-- create the customer location dimension view
DROP VIEW IF EXISTS vo_analytics.vw_dim_customer_location CASCADE;

CREATE VIEW vo_analytics.vw_dim_customer_location AS
SELECT 
    c.id AS customer_id,
    auxiliary.parse_zipcode_postalcode(c.postal_code) AS zipcode,
    city,
    state_code,
    state_name,
    st.territory_name sales_territory,
    ds.region geographic_region, 
    c.country
    FROM customer c
    JOIN auxiliary.us_state ds ON ds.state_code = auxiliary.parse_state_postalcode(c.postal_code)
    JOIN auxiliary.sales_territory st ON st.us_state_code = ds.state_code
    WHERE c.country = 'US';

-- create the sales fact view    

DROP VIEW IF EXISTS vo_analytics.vw_fact_sales CASCADE;

CREATE VIEW vo_analytics.vw_fact_sales AS
SELECT 
    stl.id sales_transaction_line_id,
    st.transaction_date AS date,
    stl.product_variant_id,
    st.customer_id,
    stl.qty AS quantity,
    stl.price_at_sale AS unit_price,
    (stl.qty * stl.price_at_sale) AS sales_amount
 FROM sales_transaction_line stl
JOIN sales_transaction st ON stl.sales_transaction_id = st.id;    

-- test the view-only analytics schema  
SELECT COUNT(*) AS fact_sales_rows FROM vo_analytics.vw_fact_sales;    
SELECT SUM(sales_amount) AS total_sales_amount FROM vo_analytics.vw_fact_sales; 

SELECT state_name, COALESCE(city, 'Total'), SUM(sales_amount) AS total_sales_amount 
    FROM vo_analytics.vw_fact_sales
    JOIN vo_analytics.vw_dim_customer_location AS cl ON vw_fact_sales.customer_id = cl.customer_id
    JOIN vo_analytics.vw_dim_date AS dd ON vw_fact_sales.date = dd.date_key
    WHERE year = 2024
    GROUP BY ROLLUP (country, state_name, city)
    ORDER BY state_name, city ASC NULLS LAST;

/*
===============================================================================
 mv-analytics SCHEMA: MATERIALIZED ANALYTICS SCHEMA
    - dimensions
        - mv_dim_date based on vw_dim_date
        - mv_dim_product based on vw_dim_product
        - mv_dim_customer_location based on vw_dim_customer_location
    - facts
        - mv_fact_sales based on vw_fact_sales
===============================================================================
*/    

-- create the schema for materialized view analytics
DROP SCHEMA IF EXISTS mv_analytics CASCADE;
CREATE SCHEMA mv_analytics; 

-- create the date dimension materialized view
DROP MATERIALIZED VIEW IF EXISTS mv_analytics.mv_dim_date;  
CREATE MATERIALIZED VIEW mv_analytics.mv_dim_date AS
SELECT * FROM vo_analytics.vw_dim_date;
-- create an index on date_key for faster joins and concurrent refreshes
CREATE UNIQUE INDEX idx_mv_dim_date ON mv_analytics.mv_dim_date (date_key);

-- create the product dimension materialized view
DROP MATERIALIZED VIEW IF EXISTS mv_analytics.mv_dim_product;  
CREATE MATERIALIZED VIEW mv_analytics.mv_dim_product AS
SELECT * FROM vo_analytics.vw_dim_product;

-- create an index on product_variant_id for faster joins and concurrent refreshes
CREATE UNIQUE INDEX idx_mv_dim_product ON mv_analytics.mv_dim_product (product_variant_id);

-- create the customer location dimension materialized view
DROP MATERIALIZED VIEW IF EXISTS mv_analytics.mv_dim_customer_location;  
CREATE MATERIALIZED VIEW mv_analytics.mv_dim_customer_location AS
SELECT * FROM vo_analytics.vw_dim_customer_location;

-- create an index on customer_id for faster joins and concurrent refreshes
CREATE UNIQUE INDEX idx_mv_dim_customer_location ON mv_analytics.mv_dim_customer_location (customer_id);

-- create the sales fact materialized view    
DROP MATERIALIZED VIEW IF EXISTS mv_analytics.mv_fact_sales;  
CREATE MATERIALIZED VIEW mv_analytics.mv_fact_sales AS
SELECT * FROM vo_analytics.vw_fact_sales;

-- create an index on sales_transaction_line_id for faster joins and concurrent refreshes
CREATE UNIQUE INDEX idx_mv_fact_sales ON mv_analytics.mv_fact_sales (sales_transaction_line_id);
-- indexes on foreign keys for faster joins
CREATE INDEX idx_mv_fact_sales_date ON mv_analytics.mv_fact_sales (date);
CREATE INDEX idx_mv_fact_sales_product_variant ON mv_analytics.mv_fact_sales (product_variant_id);
CREATE INDEX idx_mv_fact_sales_customer ON mv_analytics.mv_fact_sales (customer_id);


-- test the materialized view analytics schema  
SELECT COUNT(*) AS fact_sales_rows FROM mv_analytics.mv_fact_sales;    
SELECT SUM(sales_amount) AS total_sales_amount FROM mv_analytics.mv_fact_sales; 
SELECT state_name, COALESCE(city, 'Total'), SUM(sales_amount) AS total_sales_amount 
    FROM mv_analytics.mv_fact_sales
    JOIN mv_analytics.mv_dim_customer_location AS cl ON mv_fact_sales.customer_id = cl.customer_id
    JOIN mv_analytics.mv_dim_date AS dd ON mv_fact_sales.date = dd.date_key
    WHERE year = 2024
    GROUP BY ROLLUP (country, state_name, city)
    ORDER BY state_name, city ASC NULLS LAST;


REFRESH MATERIALIZED VIEW mv_analytics.mv_fact_sales;
REFRESH MATERIALIZED VIEW mv_analytics.mv_dim_product;
REFRESH MATERIALIZED VIEW mv_analytics.mv_dim_customer_location;
REFRESH MATERIALIZED VIEW mv_analytics.mv_dim_date;    


/*
===============================================================================
 ivmm-analytics SCHEMA: IVMM ANALYTICS SCHEMA
    - dimensions
        - dim_date will be a table generated based on vw_dim_date
        - dim_product will be a IVMM-generated table based on the same definition as vw_dim_product
        - dim_customer_location will be a IVMM-generated table based on vw_dim_customer_location
    - facts
        - fact_sales will be a IVMM-generated table based on vw_fact_sales
===============================================================================
*/ 

DROP SCHEMA IF EXISTS ivmm_analytics CASCADE;
CREATE SCHEMA ivmm_analytics;   

CREATE EXTENSION IF NOT EXISTS pg_ivm;


-- create the date dimension table. It is not dependant on source tables so we create it as a table

DROP TABLE IF EXISTS ivmm_analytics.dim_date CASCADE;
CREATE TABLE ivmm_analytics.dim_date
(date_key DATE PRIMARY KEY,
    day INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    year INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL
);  

INSERT INTO ivmm_analytics.dim_date (date_key, day, month, quarter, year, day_of_week, is_weekend)
SELECT
    d::DATE AS date_key,
    EXTRACT(DAY FROM d) AS day,
    EXTRACT(MONTH FROM d) AS month,
    EXTRACT(QUARTER FROM d) AS quarter,
    EXTRACT(YEAR FROM d) AS year,
    EXTRACT(DOW FROM d) AS day_of_week,
    CASE WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN true ELSE false END AS is_weekend
FROM
    GENERATE_SERIES('2020-01-01'::DATE, '2030-12-31'::DATE, INTERVAL '1 day') AS d;

/*
===============================================================================
 IVMM-MAINTAINED  TABLES
    - ivmm_analytics.dim_product
    - ivmm_analytics.dim_customer_location
    - ivmm_analytics.sales_facts
===============================================================================
*/
DO
$$
DECLARE 
    ivm_return_code INTEGER;
BEGIN
DROP TABLE IF EXISTS ivmm_analytics.dim_product cascade;
DROP TABLE IF EXISTS ivmm_analytics.dim_customer_location cascade;
DROP TABLE IF EXISTS ivmm_analytics.fact_sales cascade;
SELECT PGIVM.create_immv(
            'ivmm_analytics.dim_product',
            -- using single quotes to avoid conflict with dollar quoting
            ' 
            SELECT 
                pv.id as product_variant_id, attributes, 
                pvp.price as current_price, 
                pv.attributes->>''size'' as size, 
                pv.attributes->>''color'' as color,
                p.label, c.label AS category, b.label AS brand, 
                co.name AS co_name,
                co.alpha3_code AS co_alpha3_code
            FROM product_variant pv
            JOIN product_variant_price pvp ON pv.id = pvp.product_variant_id AND pvp.current = true
            JOIN product p ON pv.product_id = p.id
            JOIN category c ON p.category_id = c.id
            JOIN brand b ON p.brand_id = b.id
            JOIN country_of_origin co ON co.brand_id = b.id;
            ' 
        ) INTO ivm_return_code;
    CREATE UNIQUE INDEX idx_ivmm_dim_product ON ivmm_analytics.dim_product (product_variant_id);           
    RAISE NOTICE 'IVM Create Maintained View ivmm_analytics.dim_product returned code: %', ivm_return_code;  

    SELECT PGIVM.create_immv(
            'ivmm_analytics.dim_customer_location',
            ' 
            SELECT 
                c.id AS customer_id,
                auxiliary.parse_zipcode_postalcode(c.postal_code) AS zipcode,
                city,
                state_code,
                state_name,
                st.territory_name sales_territory,
                ds.region geographic_region, 
                c.country
                FROM customer c
                JOIN auxiliary.us_state ds ON ds.state_code = auxiliary.parse_state_postalcode(c.postal_code)
                JOIN auxiliary.sales_territory st ON st.us_state_code = ds.state_code
                WHERE c.country = ''US'';
            ' 
        ) INTO ivm_return_code;
    CREATE UNIQUE INDEX idx_ivmm_dim_customer_location ON ivmm_analytics.dim_customer_location (customer_id);       
    RAISE NOTICE 'IVM Create Maintained View ivmm_analytics.dim_customer_location returned code: %', ivm_return_code;    

    SELECT PGIVM.create_immv(
            'ivmm_analytics.fact_sales',
            ' 
            SELECT 
                stl.id sales_transaction_line_id,
                st.transaction_date AS date,
                stl.product_variant_id,
                st.customer_id,
                stl.qty AS quantity,
                stl.price_at_sale AS unit_price,
                (stl.qty * stl.price_at_sale) AS sales_amount
             FROM sales_transaction_line stl
            JOIN sales_transaction st ON stl.sales_transaction_id = st.id;    
            ' 
        ) INTO ivm_return_code;
    CREATE UNIQUE INDEX idx_ivmm_fact_sales ON ivmm_analytics.fact_sales (sales_transaction_line_id);        
    CREATE INDEX idx_ivmm_fact_sales_date ON ivmm_analytics.fact_sales (date);
    CREATE INDEX idx_ivmm_fact_sales_product_variant ON ivmm_analytics.fact_sales (product_variant_id);
    CREATE INDEX idx_ivmm_fact_sales_customer ON ivmm_analytics.fact_sales (customer_id);
    RAISE NOTICE 'IVM Create Maintained View ivmm_analytics.fact_sales returned code: %', ivm_return_code;
END;
$$ LANGUAGE plpgsql;

--        

-- test the IVMM schema  
SELECT COUNT(*) AS fact_sales_rows FROM ivmm_analytics.fact_sales;    
SELECT SUM(sales_amount) AS total_sales_amount FROM ivmm_analytics.fact_sales;

SELECT state_name, COALESCE(city, 'Total'), SUM(sales_amount) AS total_sales_amount 
    FROM ivmm_analytics.fact_sales
    JOIN ivmm_analytics.dim_customer_location AS cl ON fact_sales.customer_id = cl.customer_id
    JOIN ivmm_analytics.dim_date AS dd ON fact_sales.date = dd.date_key
    WHERE year = 2024
    GROUP BY ROLLUP (state_name, city)
    ORDER BY state_name, city ASC NULLS LAST;


