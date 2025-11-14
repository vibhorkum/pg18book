/* 
===============================================================================
 DESCRIPTION: SQL script file to set up analytics star schemas in the central_analytics
              database.
    Dimensions:
        - date
        - product
        - customer and localtion
    Facts:
        - sales (at the sales_transaction_line level)

 We will show three approaches
    1. View-only approach (except for the date dimension table and the auxiliairy tables for state and territory)
        - uses vo_analytics schema
    2. Materialized view approach with periodic refresh (same as view-only but with better performance)
        - uses mv_analytics schema
    3. Table-based appraoach using insert/update/delete triggers to maintain the fact table
        - uses tt_analytics schema
The auxilliary schema contains supporting tables and functions to help build the dimension tables and views

===============================================================================
*/


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
    v_state_code := SUBSTRING(zipcode, 1, 2);
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
 vo_analytics SCHEMA: VIEW-ONLY ANALYTICS SCHEMA
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

/*
===============================================================================
 mv_analytics SCHEMA: MATERIALIZED ANALYTICS SCHEMA
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



/*
===============================================================================
 tt_analytics SCHEMA: TABLE-BASED ANALYTICS SCHEMA
    - dimensions
        - dim_date will be a table generated based on vw_dim_date
        - dim_product will be a table maintained by a set of insert/update/delete triggers based on the tables in the product schema
        - dim_customer_location will be a table maintained by a set of insert/update/delete triggers based on the customer table
    - facts
        - fact_sales will be a table maintained by a set of insert/update/delete triggers based on the sales tables
===============================================================================
*/ 

DROP SCHEMA IF EXISTS tt_analytics CASCADE;
CREATE SCHEMA tt_analytics;   


-- create the date dimension table. It is not dependant on replication so we can just create it directly.

DROP TABLE IF EXISTS tt_analytics.dim_date CASCADE;
CREATE TABLE tt_analytics.dim_date
(date_key DATE PRIMARY KEY,
    day INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    year INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL
);  

INSERT INTO tt_analytics.dim_date (date_key, day, month, quarter, year, day_of_week, is_weekend)
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


-- create the customer location dimension table  

DROP TABLE IF EXISTS tt_analytics.dim_customer_location CASCADE;
CREATE TABLE tt_analytics.dim_customer_location (
    customer_id UUID PRIMARY KEY,
    zipcode CHAR(5),
    city VARCHAR(100),
    state_code CHAR(2),
    state_name VARCHAR(50),
    sales_territory VARCHAR(100),
    geographic_region VARCHAR(50),
    country VARCHAR(50)
);

-- create the triggers and functions to maintain the dim_customer_location table

CREATE OR REPLACE FUNCTION tt_analytics.sf_insert_customer () 
RETURNS TRIGGER AS
$$
  BEGIN
    RAISE NOTICE 'Inserting customer location for customer_id: %', NEW.id;
    -- RAISE NOTICE 'Parsed state_code: %', auxiliary.parse_state_postalcode(NEW.postal_code);
    INSERT INTO tt_analytics.dim_customer_location (
        customer_id, zipcode, city, state_code, state_name, sales_territory, geographic_region, country)
    VALUES (
        NEW.id,
        auxiliary.parse_zipcode_postalcode(NEW.postal_code),
        NEW.city,
        auxiliary.parse_state_postalcode(NEW.postal_code),
        (SELECT state_name FROM auxiliary.us_state WHERE state_code = auxiliary.parse_state_postalcode(NEW.postal_code)),
        (SELECT territory_name FROM auxiliary.sales_territory WHERE us_state_code = auxiliary.parse_state_postalcode(NEW.postal_code)),
        (SELECT region FROM auxiliary.us_state WHERE state_code = auxiliary.parse_state_postalcode(NEW.postal_code)),
        NEW.country
    );
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION tt_analytics.sf_update_customer () 
RETURNS TRIGGER AS
$$
  BEGIN
    UPDATE tt_analytics.dim_customer_location
    SET
        zipcode = auxiliary.parse_zipcode_postalcode(NEW.postal_code),
        city = NEW.city,
        state_code = auxiliary.parse_state_postalcode(NEW.postal_code),
        state_name = (SELECT state_name FROM auxiliary.us_state WHERE state_code = auxiliary.parse_state_postalcode(NEW.postal_code)),
        sales_territory = (SELECT territory_name FROM auxiliary.sales_territory WHERE us_state_code = auxiliary.parse_state_postalcode(NEW.postal_code)),
        geographic_region = (SELECT region FROM auxiliary.us_state WHERE state_code = auxiliary.parse_state_postalcode(NEW.postal_code)),
        country = NEW.country
    WHERE customer_id = NEW.id;
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION tt_analytics.sf_delete_customer () 
RETURNS TRIGGER AS
$$
  BEGIN
    DELETE FROM tt_analytics.dim_customer_location
    WHERE customer_id = OLD.id;
    RETURN OLD;
  END;
$$ LANGUAGE PLPGSQL;    
CREATE TRIGGER tr_insert_customer 
  AFTER INSERT
  ON customer.customer FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_insert_customer(); 
CREATE TRIGGER tr_update_customer 
  AFTER UPDATE
  ON customer.customer FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_customer(); 
CREATE TRIGGER tr_delete_customer 
  AFTER DELETE
  ON customer.customer FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_delete_customer();
-- enable the replica triggers
ALTER TABLE customer.customer ENABLE REPLICA TRIGGER tr_insert_customer;
ALTER TABLE customer.customer ENABLE REPLICA TRIGGER tr_update_customer;
ALTER TABLE customer.customer ENABLE REPLICA TRIGGER tr_delete_customer;


-- create the product dimension table   
DROP TABLE IF EXISTS tt_analytics.dim_product CASCADE;
CREATE TABLE tt_analytics.dim_product (
    product_variant_id INTEGER PRIMARY KEY,
    attributes JSONB,
    current_price NUMERIC(10,2),
    size VARCHAR(20),
    color VARCHAR(20),
    label VARCHAR(100),
    category VARCHAR(100),
    brand VARCHAR(100),
    co_name VARCHAR(100),
    co_alpha3_code VARCHAR(3)
);

-- create the triggers and functions to maintain the dim_product table
-- this will include triggers on 
    -- product_variant
    -- product_variant_price
    -- product (only needs update trigger as product cannot be deleted if there are variants)
    -- category (only needs update trigger as category cannot be deleted if there are variants)
    -- brand (only needs update trigger as brand cannot be deleted if there are variants)
    -- country_of_origin (only needs update trigger as coo cannot be deleted if there are variants)

-- create trigger and function for product_variant insert, update, and delete
CREATE OR REPLACE FUNCTION tt_analytics.sf_upsert_product_variant () 
RETURNS TRIGGER AS
$$
  BEGIN
    INSERT INTO tt_analytics.dim_product (
        product_variant_id, attributes, current_price, size, color, label, category, brand, co_name, co_alpha3_code)
    VALUES (
        NEW.id,
        NEW.attributes,
        (SELECT price FROM product.product_variant_price WHERE product_variant_id = NEW.id AND current = true),
        NEW.attributes->>'size',
        NEW.attributes->>'color',
        (SELECT p.label FROM product.product p 
            JOIN product.product_variant pv ON pv.product_id = p.id WHERE pv.id = NEW.id),
        (SELECT c.label FROM product.category c 
            JOIN product.product p ON p.category_id = c.id 
            JOIN product.product_variant pv ON pv.product_id = p.id WHERE pv.id = NEW.id),
        (SELECT b.label FROM product.brand b 
            JOIN product.product p ON p.brand_id = b.id 
            JOIN product.product_variant pv ON pv.product_id = p.id WHERE pv.id = NEW.id),
        (SELECT co.name FROM product.country_of_origin co 
            JOIN product.brand b ON co.brand_id = b.id 
            JOIN product.product p ON p.brand_id = b.id 
            JOIN product.product_variant pv ON pv.product_id = p.id WHERE pv.id = NEW.id),
        (SELECT co.alpha3_code FROM product.country_of_origin co 
            JOIN product.brand b ON co.brand_id = b.id 
            JOIN product.product p ON p.brand_id = b.id 
            JOIN product.product_variant pv ON pv.product_id = p.id WHERE pv.id = NEW.id)
    )
    ON CONFLICT (product_variant_id) DO UPDATE SET
        attributes = EXCLUDED.attributes,
        current_price = EXCLUDED.current_price,
        size = EXCLUDED.size,
        color = EXCLUDED.color,
        label = EXCLUDED.label,
        category = EXCLUDED.category,
        brand = EXCLUDED.brand,
        co_name = EXCLUDED.co_name,
        co_alpha3_code = EXCLUDED.co_alpha3_code;
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER tr_upsert_product_variant 
  AFTER INSERT OR UPDATE
  ON product.product_variant FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_upsert_product_variant(); 
-- enable the replica trigger
ALTER TABLE product.product_variant ENABLE REPLICA TRIGGER tr_upsert_product_variant;

-- create tables and trigger for product_variant delete
CREATE OR REPLACE FUNCTION tt_analytics.sf_delete_product_variant () 
RETURNS TRIGGER AS
$$
  BEGIN
    DELETE FROM tt_analytics.dim_product
    WHERE product_variant_id = OLD.id;
    RETURN OLD;
  END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER tr_delete_product_variant 
  AFTER DELETE
  ON product.product_variant FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_delete_product_variant(); 
-- enable the replica trigger
ALTER TABLE product.product_variant ENABLE REPLICA TRIGGER tr_delete_product_variant;



-- create the trigger and function to handle updates to product_variant_price to maintain current price
CREATE OR REPLACE FUNCTION tt_analytics.sf_update_product_variant_price () 
RETURNS TRIGGER AS
$$
  BEGIN
    IF NEW.current = true THEN
        UPDATE tt_analytics.dim_product
        SET current_price = NEW.price
        WHERE product_variant_id = NEW.product_variant_id;
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER tr_update_product_variant_price 
  AFTER INSERT OR UPDATE
  ON product.product_variant_price FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_product_variant_price(); 
-- enable the replica trigger
ALTER TABLE product.product_variant_price ENABLE REPLICA TRIGGER tr_update_product_variant_price;

-- create the trigger and function to handle updates to product to maintain label, category, brand, co_name, co_alpha3_code
CREATE OR REPLACE FUNCTION tt_analytics.sf_update_product () 
RETURNS TRIGGER AS
$$
  BEGIN
    UPDATE tt_analytics.dim_product
    SET
        label = NEW.label,
        category = (SELECT c.label FROM product.category c WHERE c.id = NEW.category_id),
        brand = (SELECT b.label FROM product.brand b WHERE b.id = NEW.brand_id),
        co_name = (SELECT co.name FROM product.country_of_origin co 
                    JOIN product.brand b ON co.brand_id = b.id WHERE b.id = NEW.brand_id),
        co_alpha3_code = (SELECT co.alpha3_code FROM product.country_of_origin co 
                    JOIN product.brand b ON co.brand_id = b.id WHERE b.id = NEW.brand_id)
    WHERE product_variant_id IN (SELECT pv.id FROM product.product_variant pv WHERE pv.product_id = NEW.id);
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER tr_update_product 
  AFTER UPDATE
  ON product.product FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_product(); 
-- enable the replica trigger
ALTER TABLE product.product ENABLE REPLICA TRIGGER tr_update_product;

-- create the triggers and functions to handle updates to the category table
CREATE OR REPLACE FUNCTION tt_analytics.sf_update_category () 
RETURNS TRIGGER AS
$$
  BEGIN
    UPDATE tt_analytics.dim_product
    SET category = NEW.label
    WHERE product_variant_id IN (SELECT pv.id FROM product.product_variant pv 
                                    JOIN product.product p ON pv.product_id = p.id WHERE p.category_id = NEW.id);
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER tr_update_category 
  AFTER UPDATE
  ON product.category FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_category(); 
-- enable the replica trigger
ALTER TABLE product.category ENABLE REPLICA TRIGGER tr_update_category;

-- create the triggers and functions to handle updates to the brand table
CREATE OR REPLACE FUNCTION tt_analytics.sf_update_brand () 
RETURNS TRIGGER AS
$$
  BEGIN
    UPDATE tt_analytics.dim_product
    SET brand = NEW.label
    WHERE product_variant_id IN (SELECT pv.id FROM product.product_variant pv 
                                    JOIN product.product p ON pv.product_id = p.id WHERE p.brand_id = NEW.id);
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER tr_update_brand 
  AFTER UPDATE
  ON product.brand FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_brand(); 
-- enable the replica trigger
ALTER TABLE product.brand ENABLE REPLICA TRIGGER tr_update_brand;

-- create the triggers and functions to handle updates to the country_of_origin table
CREATE OR REPLACE FUNCTION tt_analytics.sf_update_country_of_origin () 
RETURNS TRIGGER AS
$$
  BEGIN
    UPDATE tt_analytics.dim_product
    SET
        co_name = NEW.name,
        co_alpha3_code = NEW.alpha3_code
    WHERE product_variant_id IN (SELECT pv.id FROM product.product_variant pv 
                                    JOIN product.product p ON pv.product_id = p.id 
                                    JOIN product.brand b ON p.brand_id = b.id WHERE b.id = NEW.brand_id);
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER tr_update_country_of_origin 
  AFTER UPDATE
  ON product.country_of_origin FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_country_of_origin(); 
-- enable the replica trigger
ALTER TABLE product.country_of_origin ENABLE REPLICA TRIGGER tr_update_country_of_origin;




-- create the sales fact table   
DROP TABLE IF EXISTS tt_analytics.fact_sales CASCADE;
CREATE TABLE tt_analytics.fact_sales (
    sales_transaction_line_id UUID PRIMARY KEY,
    date DATE NOT NULL,
    product_variant_id INTEGER NOT NULL,
    customer_id UUID NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    sales_amount NUMERIC(12,2) NOT NULL
);

-- create the triggers and functions to maintain the fact_sales table
CREATE OR REPLACE FUNCTION tt_analytics.sf_insert_sales_transaction_line () 
RETURNS TRIGGER AS
$$
  BEGIN
    INSERT INTO tt_analytics.fact_sales (
        sales_transaction_line_id, date, product_variant_id, customer_id, quantity, unit_price, sales_amount)
    VALUES (
        NEW.id,
        (SELECT transaction_date FROM sales.sales_transaction WHERE id = NEW.sales_transaction_id),
        NEW.product_variant_id,
        (SELECT customer_id FROM sales.sales_transaction WHERE id = NEW.sales_transaction_id),
        NEW.qty,
        NEW.price_at_sale,
        (NEW.qty * NEW.price_at_sale)
    );
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION tt_analytics.sf_update_sales_transaction_line () 
RETURNS TRIGGER AS
$$
  BEGIN
    UPDATE tt_analytics.fact_sales
    SET
        date = (SELECT transaction_date FROM sales.sales_transaction WHERE id = NEW.sales_transaction_id),
        product_variant_id = NEW.product_variant_id,
        customer_id = (SELECT customer_id FROM sales.sales_transaction WHERE id = NEW.sales_transaction_id),
        quantity = NEW.qty,
        unit_price = NEW.price_at_sale,
        sales_amount = (NEW.qty * NEW.price_at_sale)
    WHERE sales_transaction_line_id = NEW.id;
    RETURN NEW;
  END;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION tt_analytics.sf_delete_sales_transaction_line () 
RETURNS TRIGGER AS
$$
  BEGIN
    DELETE FROM tt_analytics.fact_sales
    WHERE sales_transaction_line_id = OLD.id;
    RETURN OLD;
  END;
$$ LANGUAGE PLPGSQL;    
CREATE TRIGGER tr_insert_sales_transaction_line 
  AFTER INSERT
  ON sales.sales_transaction_line FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_insert_sales_transaction_line(); 

CREATE TRIGGER tr_update_sales_transaction_line 
  AFTER UPDATE
  ON sales.sales_transaction_line FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_update_sales_transaction_line(); 
CREATE TRIGGER tr_delete_sales_transaction_line 
  AFTER DELETE
  ON sales.sales_transaction_line FOR EACH ROW EXECUTE FUNCTION tt_analytics.sf_delete_sales_transaction_line();
-- enable the replica triggers
ALTER TABLE sales.sales_transaction_line ENABLE REPLICA TRIGGER tr_insert_sales_transaction_line;
ALTER TABLE sales.sales_transaction_line ENABLE REPLICA TRIGGER tr_update_sales_transaction_line;
ALTER TABLE sales.sales_transaction_line ENABLE REPLICA TRIGGER tr_delete_sales_transaction_line;

