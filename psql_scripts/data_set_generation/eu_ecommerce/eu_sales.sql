/* this generates the us_ecommerce_data_set (stored as text backup in us_ecommerce_data_set) from us_ecommerce_data_seed 

generate the sales transactions with a skew that shows (a) that polos tend to be bought with sports coats and suit coats
and (b) blue jeans and T-shirts are bought together

Approach:
1) Iterate through the customers
    - Create a random set of sales transactions (between 1 and 10) spread over three years, using random products

2) Pick 25% of the customers at random
    - Create an order for 1-2 (random) polos and 1 sports coat

3) Pick 40% of the customers at random
    - Create 2 orders for 1-2 (random) T-shirts and 1 blue jeans    
*/

\c eu_ecommerce_data

CREATE SCHEMA IF NOT EXISTS data_generation;

CREATE OR REPLACE PROCEDURE data_generation.generate_random_sales_transaction_data ()
AS
$$
DECLARE
    customer_record RECORD;
    customer_count INTEGER;
    random_date DATE;
    sales_transaction_id UUID;
    sales_transaction_lines INTEGER;
    p_id INTEGER;
    p_price NUMERIC;
BEGIN
    SET search_path = eu_sales, eu_customer, product_reference;
    SELECT COUNT(*) INTO customer_count FROM customer;
    --- create random orders for 75% of customers, spread over the last 18 months
    FOR customer_record IN SELECT id FROM customer ORDER BY RANDOM() LIMIT customer_count*0.75
        LOOP
            --- select random date within last 18 months
            random_date := current_date - TRUNC(RANDOM() * 150)::INTEGER;
            INSERT INTO sales_transaction (id, transaction_date, customer_id)
                VALUES (gen_random_uuid(), random_date, customer_record.id)
                RETURNING id INTO sales_transaction_id;
            --- add between 1 and 4 product_variants to the order    
            sales_transaction_lines:= TRUNC(RANDOM() * 3) +1;
            FOR i IN 1.. sales_transaction_lines LOOP
                --- select a random product variant with its price
                SELECT 
                    p.id, pp.price INTO p_id, p_price
                    FROM product p, product_price pp
                    WHERE p.id = pp.product_id
                    ORDER BY RANDOM() LIMIT 1;
                --- create a sales transaction line    
                INSERT INTO sales_transaction_line (id, sales_transaction_id, product_id, price_at_sale, qty)
                    VALUES (gen_random_uuid(), sales_transaction_id, p_id, p_price, 1);
            END LOOP;
        END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE data_generation.generate_tshirt_jeans_sales_transaction_data (ratio NUMERIC DEFAULT 0.25)
AS
$$
DECLARE
    customer_record RECORD;
    customer_count INTEGER;
    random_date DATE;
    sales_transaction_id UUID;
    p_id INTEGER;
    p_price NUMERIC;
BEGIN
SET search_path = eu_sales, eu_customer, product_reference;
SELECT COUNT(*) INTO customer_count FROM customer;
    --- create t-shirt and jeans orders for subset of customers, spread over the last 18 months
    FOR customer_record IN SELECT id FROM customer ORDER BY RANDOM() LIMIT customer_count*ratio
        LOOP
            --- select random date within last 18 months
            random_date := current_date - TRUNC(RANDOM() * 150)::INTEGER;
            INSERT INTO sales_transaction (id, transaction_date, customer_id)
                VALUES (UUIDV7(), random_date, customer_record.id)
                RETURNING id INTO sales_transaction_id;
            --- select product  and price for t-shirts
            SELECT 
                p.id, pp.price INTO p_id, p_price
                FROM product p, product_price pp
                WHERE p.id = pp.product_id AND p.label ilike '%t-shirt%'
                ORDER BY RANDOM() LIMIT 1;
            IF p_id <> NULL THEN    
                INSERT INTO sales_transaction_line (id, sales_transaction_id, product_variant_id, price_at_sale, qty)
                    VALUES (UUIDV7(), sales_transaction_id, pv_id, pv_price, 1);
            END IF;    
            --- select product variant and price for jeans
            SELECT 
                p.id, pp.price INTO p_id, p_price
                FROM product p, product_price pp
                WHERE p.id = pp.product_id AND p.label ilike '%jeans%'
                ORDER BY RANDOM() LIMIT 1;
            IF p_id <> NULL THEN    
                INSERT INTO sales_transaction_line (id, sales_transaction_id, product_id, price_at_sale, qty)
                    VALUES (gen_random_uuid(), sales_transaction_id, p_id, p_price, 1);
            END IF;        
        END LOOP;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE data_generation.generate_polo_sports_coat_sales_transaction_data (ratio NUMERIC DEFAULT 0.25)
AS
$$
DECLARE
    customer_record RECORD;
    customer_count INTEGER;
    random_date DATE;
    sales_transaction_id UUID;
    p_id INTEGER;
    p_price NUMERIC;
BEGIN
SET search_path = eu_sales, eu_customer, product_reference;
SELECT COUNT(*) INTO customer_count FROM customer;
    --- create polo and sports coat orders for subset of customers, spread over the last 18 months
    FOR customer_record IN SELECT id FROM customer ORDER BY RANDOM() LIMIT customer_count*ratio
        LOOP
            --- select random date within last 18 months
            random_date := current_date - TRUNC(RANDOM() * 150)::INTEGER;
            INSERT INTO sales_transaction (id, transaction_date, customer_id)
                VALUES (gen_random_uuid(), random_date, customer_record.id)
                RETURNING id INTO sales_transaction_id;
            --- select product variant and price for polos
            SELECT 
                p.id, pp.price INTO p_id, p_price
                FROM product p, product_price pp
                WHERE p.id = pp.product_id AND p.label ilike '%polo%'
                ORDER BY RANDOM() LIMIT 1;
            IF p_id <> NULL THEN    
                INSERT INTO sales_transaction_line (id, sales_transaction_id, product_id, price_at_sale, qty)
                     VALUES (gen_random_uuid(), sales_transaction_id, pv_id, pv_price, 1);
            END IF;
            --- select product variant and price for sports coat
                        SELECT 
                p.id, pp.price INTO p_id, p_price
                FROM product p, product_price pp
                WHERE p.id = pp.product_id AND p.label ilike '%sports coat%'
                ORDER BY RANDOM() LIMIT 1;
            IF p_id <> NULL THEN     
                INSERT INTO sales_transaction_line (id, sales_transaction_id, product_id, price_at_sale, qty)
                    VALUES (gen_random_uuid(), sales_transaction_id, p_id, p_price, 1);
            END IF;        
        END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE data_generation.generate_sales_transaction_data ()
AS
$$
    DECLARE counter INTEGER;
    BEGIN
        SET search_path = eu_sales, eu_customer, product_reference;
        SELECT COUNT(*) INTO counter FROM sales_transaction;
        RAISE NOTICE 'Truncating % sales transactions', counter ;
        TRUNCATE sales_transaction CASCADE;
        RAISE NOTICE 'Truncated Sales Transactions';
        RAISE NOTICE 'Creating base random transactions';
        CALL data_generation.generate_random_sales_transaction_data ();
        SELECT COUNT(*) INTO counter FROM sales_transaction;
        RAISE NOTICE 'Created % base random transactions', counter;
        RAISE NOTICE 'Creating t-shirt jeans  transactions';
        CALL data_generation.generate_tshirt_jeans_sales_transaction_data (.25);
        RAISE NOTICE 'Creating polo sports coats  transactions';
        CALL data_generation.generate_polo_sports_coat_sales_transaction_data (.25);
        SELECT COUNT(*) INTO counter FROM sales_transaction;
        RAISE NOTICE 'Generated % sales transactions', counter;
    END;
$$ LANGUAGE PLPGSQL;

call data_generation.generate_sales_transaction_data();

DROP PROCEDURE data_generation.generate_random_sales_transaction_data;
DROP PROCEDURE data_generation.generate_tshirt_jeans_sales_transaction_data;
DROP PROCEDURE data_generation.generate_polo_sports_coat_sales_transaction_data;
DROP PROCEDURE data_generation.generate_sales_transaction_data;
DROP SCHEMA data_generation;
