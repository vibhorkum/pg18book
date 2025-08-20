
DO 
$$
DECLARE x INTEGER := 4;
BEGIN
    IF x = 1 OR x = 2 THEN 
        RAISE NOTICE 'The value is either 1 or 2';
    ELSEIF x = 3 THEN
        RAISE NOTICE 'The value is 3';
    ELSE
        RAISE NOTICE 'The value is neither 1, 2, or 3';
    END IF;
END
$$;

-- Simple CASE
DO 
$$
DECLARE x INTEGER := 4;
BEGIN
    CASE x
        WHEN 1, 2 THEN 
            RAISE NOTICE 'The value is either 1 or 2';
        WHEN 3 THEN
            RAISE NOTICE 'The value is 3';
        ELSE 
            RAISE NOTICE 'The value is neither 1, 2, or 3';
    END CASE;
END
$$;

-- Searched CASE
DO 
$$
DECLARE x INTEGER := 4;
BEGIN
    CASE 
        WHEN x IN (1, 2) THEN 
            RAISE NOTICE 'The value is either 1 or 2';
        WHEN x = 3 THEN
            RAISE NOTICE 'The value is 3';
        ELSE 
            RAISE NOTICE 'The value is neither 1, 2, or 3';
    END CASE;
END
$$;

-- LOOP and EXIT

DO 
$$
DECLARE 
    v_max INTEGER := 4;
    v_ctr INTEGER :=1;
BEGIN
    LOOP
        RAISE NOTICE 'Iteration # %', v_ctr;
        IF v_ctr >= v_max THEN 
            EXIT; 
        ELSE 
            v_ctr := v_ctr +1;
        END IF;
    END LOOP;
END        
$$;

-- FOR ... LOOP

DO 
$$
DECLARE 
    v_max INTEGER := 4;
BEGIN
    FOR v_ctr IN 1.. v_max LOOP
        RAISE NOTICE 'Iteration # %', v_ctr;
    END LOOP;
END        
$$;


-- FOR EACH ... LOOP

-- looping through a one-dimensional array 
DO 
$$
DECLARE 
    v_array INTEGER[]:= '{1,2,3,4}';
    v_i INTEGER;
BEGIN
    FOREACH v_i IN ARRAY v_array LOOP
        RAISE NOTICE 'Iteration # %', v_i;
    END LOOP;
END        
$$;

-- looping through a two-dimensional array 
DO 
$$
DECLARE 
    v_array INTEGER[][]:= '{{1,2},{2,3},{3,5},{4,7}}';
    v_i INTEGER[];
BEGIN
    FOREACH v_i SLICE 1 IN ARRAY v_array LOOP
        RAISE NOTICE 'Prime number # % = %', v_i[1], v_i[2];
    END LOOP;
END        
$$;

-- increasing the prices for all products by 3%

DO $$
DECLARE 
    v_product_variant_price_record RECORD;
    v_new_price NUMERIC;
    v_old_price NUMERIC;
BEGIN
    --- update all currently active prices by 3%
    UPDATE product_variant_price
        SET price = price + 0.03 * price
        WHERE current = TRUE;
    -- find all the current product prices that are close to the round number
    -- and adjust them to 0.99
    FOR v_product_variant_price_record 
        IN 
        (SELECT * FROM product_variant_price 
            WHERE 
                current = TRUE
            AND (
                    (price - TRUNC (price)) > .70 
                    OR 
                    (price - TRUNC (price)) < .10
                )
        )
        LOOP
            UPDATE product_variant_price 
                SET price = TRUNC (price) + 0.99
                WHERE product_variant_price.id = v_product_variant_price_record.id 
                -- use new PostgreSQL 18 capability to return old and new
                RETURNING NEW.price, OLD.price INTO v_new_price, v_old_price;
            RAISE NOTICE 'Changed price for id % from % to %', v_product_variant_price_record.id, v_old_price, v_new_price; 
        END LOOP;
END;
$$;

DO $$
DECLARE
    v_call_stack TEXT;
    v_row_count INTEGER;
    v_OID OID;
BEGIN
    PERFORM  * FROM product;
    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    GET DIAGNOSTICS v_OID = PG_ROUTINE_OID;
    GET DIAGNOSTICS v_call_stack = PG_CONTEXT;
    IF FOUND THEN 
        RAISE NOTICE 'Query successful. Found % rows', v_row_count;
    ELSE 
        RAISE NOTICE 'Nothing found';
    END IF;
    RAISE NOTICE E'--- Call Stack ---\n%', v_call_stack;
END;
$$;

-------------------------------------------------------------------------------

-- Exception handling

DO $$
BEGIN
    -- this will fail as table constraint requires prices > 0
    UPDATE product_variant_price SET price = 0.99 WHERE id = 1;
    EXCEPTION WHEN OTHERS THEN   
        RAISE NOTICE 'Update failed';
END;
$$;


DO $$
    DECLARE 
    v_RETURNED_SQLSTATE TEXT; 
    v_COLUMN_NAME TEXT; 
    v_MESSAGE_TEXT TEXT;
    v_CONSTRAINT_NAME TEXT; 
    v_TABLE_NAME TEXT;
BEGIN
    -- this will fail as table constraint requires prices > 0
    UPDATE product_variant_price SET price = '-0.99' WHERE id = 1;
    EXCEPTION 
        WHEN check_violation THEN
            RAISE NOTICE 'Violated check constraint; Details below';
            GET STACKED DIAGNOSTICS 
                v_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                v_COLUMN_NAME = COLUMN_NAME,
                v_CONSTRAINT_NAME = CONSTRAINT_NAME,
                v_MESSAGE_TEXT = MESSAGE_TEXT,
                v_TABLE_NAME = TABLE_NAME;
            RAISE NOTICE 'Detailed state % on column %', v_RETURNED_SQLSTATE, v_COLUMN_NAME;
            RAISE NOTICE 'CONSTRAINT_NAME %', v_CONSTRAINT_NAME;
            RAISE NOTICE 'MESSAGE_TEXT %',v_MESSAGE_TEXT;
            RAISE NOTICE 'TABLE_NAME %', v_TABLE_NAME;
END;
$$;


DO $$
BEGIN
    UPDATE product_variant_price SET price = 0.01 WHERE id =1;
    RAISE check_violation USING MESSAGE = 'Price too low';
END $$;    

-------------------------------------------------------------------------------

/*

Section: Triggers – Reacting to Data Changes and Events
*/

\c east_ecommerce_data

-- adding three additional columns to the inventory table
ALTER TABLE product_variant_inventory 
    ADD COLUMN last_update_timestamp TIMESTAMP,
    ADD COLUMN last_update_user TEXT,
    ADD COLUMN prior_value JSONB;



-- defining a before trigger for insert and update that tracks the changes

CREATE OR REPLACE FUNCTION tr_inventory_last_update() RETURNS TRIGGER 
AS
  $$
    BEGIN
        NEW.last_update_timestamp = NOW();
        NEW.last_update_user = CURRENT_USER;
        NEW.prior_value = TO_JSONB (OLD);
        RETURN NEW; -- returns the new row
    END
  $$ LANGUAGE PLPGSQL;

-- adding the trigger to the table as a BEFORE trigger for INSERT and UPDATE
CREATE OR REPLACE TRIGGER tr_track_last_update_inventory
    BEFORE INSERT OR UPDATE
    ON product_variant_inventory FOR EACH ROW EXECUTE FUNCTION tr_inventory_last_update(); 
  

/*

Section: Subtransactions

*/


CREATE OR REPLACE FUNCTION sf_add_lines_to_sales_order (
    p_sales_transaction_id TEXT, -- sales transaction
    p_line_info NUMERIC[][][]) --- order lines with product, qty, and price
    RETURNS INTEGER[][] --- product and quantities that were committed successfully
AS
$$
DECLARE
    v_products_ordered INTEGER[][]; -- result array of all successful lines
    v_pv_id INTEGER;
    v_qty INTEGER;
    v_price NUMERIC;
BEGIN
    -- iterate through all the lines and commit the inventory
    FOR v_i IN 1.. ARRAY_LENGTH(p_line_info, 1) LOOP
            BEGIN -- start a new subtransaction for each line of the order
            v_pv_id := p_line_info[v_i][1];
            v_qty := p_line_info[v_i][2];
            v_price := p_line_info[v_i][3];
            -- add the sales transaction line
            INSERT INTO sales_transaction_line 
                (sales_transaction_id, product_variant_id, qty, price_at_sale)
                VALUES 
                (p_sales_transaction_id,v_pv_id,v_qty,v_price);
            -- commit the inventory
            UPDATE product_variant_inventory SET qty = qty - v_qty
                WHERE product_variant_id = v_pv_id;
            RAISE NOTICE 'Success with order % for % units. Sufficient inventory on hand',
                         v_pv_id, v_qty;
            -- add this successful line to the return result
            v_products_ordered := v_products_ordered || ARRAY[[v_pv_id, v_qty]];
            -- In case of an exception in this subtransaction, the latest line will be rolled back
            -- all other lines will be committed, unless there is another error that is not handled
            EXCEPTION -- handle exceptions that pertain to this line of the order
                WHEN check_violation THEN   
                    RAISE NOTICE 'Failure with % for % units. Out of inventory', p_line_info[v_i][1], p_line_info[v_i][2];
            END;
    END LOOP;     
    RETURN v_products_ordered;
END $$ LANGUAGE PLPGSQL;    


-- Invoke the function defined above, after resetting the inventory level and the specific sales transaction
-- remove all other sales transaction lines from sales transaction to simplify output
DELETE FROM sales_transaction_line WHERE sales_transaction_id = 'east_5316';
-- reset the inventory to create the 'Out of inventory' condition
UPDATE product_variant_inventory set qty = 1 WHERE product_variant_id IN (1,7,8,18,19);

SELECT sf_add_lines_to_sales_order AS committed_lines 
    FROM sf_add_lines_to_sales_order(
        'east_5316', 
        '{{1,1,29.11}, {7,1,15}, {8,1, 32}, {18,3, 58}, {19,1, 5.23}}');

/*

Section: pg_background
Running with 
east_ecommerce_data=# SHOW max_worker_processes;
 max_worker_processes 
----------------------
 20
(1 row)


*/

\c east_ecommerce_data;

CREATE EXTENSION pg_background;

CREATE TABLE inventory_request (
    time TIMESTAMP, 
    product_variant_id INTEGER, 
    sales_transaction_id TEXT, 
    qty INTEGER);


CREATE OR REPLACE PROCEDURE record_inventory_request (
    p_product_variant_id INTEGER, 
    p_sales_transaction_id TEXT, 
    p_qty INTEGER)
AS
$$
BEGIN
    INSERT INTO inventory_request 
        (time, product_variant_id,sales_transaction_id, qty)
    VALUES (CLOCK_TIMESTAMP(), p_product_variant_id,p_sales_transaction_id, p_qty);
END
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION sf_add_lines_to_sales_order (
    p_sales_transaction_id TEXT, -- sales transaction
    p_line_info NUMERIC[][][]) --- order lines with product, qty, and price
    RETURNS INTEGER[][] --- product and quantities that were committed successfully
AS
$$
DECLARE
    v_products_ordered INTEGER[][]; -- result array of all successful lines
    v_pv_id INTEGER;
    v_qty INTEGER;
    v_price NUMERIC;
BEGIN
    -- iterate through all the lines and commit the inventory
    FOR v_i IN 1.. ARRAY_LENGTH(p_line_info, 1) LOOP
            BEGIN -- start a new subtransaction for each line of the order
            v_pv_id := p_line_info[v_i][1];
            v_qty := p_line_info[v_i][2];
            v_price := p_line_info[v_i][3];
            -- document the inventory request -- trying different things

            -- 1) this creates the record for all successful transactions (as expected)
            -- CALL record_inventory_request (v_pv_id, p_sales_transaction_id, v_qty);
            
            -- 2) this errors out with message column "v_pv_id" does not exist
            -- SELECT * FROM pg_background_result(pg_background_launch('CALL record_inventory_request (v_pv_id, p_sales_transaction_id, v_qty)')) as (result TEXT);

            -- 3) does not add any records in the inventory request table 
            -- PERFORM pg_background_launch('CALL record_inventory_request (v_pv_id, p_sales_transaction_id, v_qty)');
            -- add the sales transaction line
            INSERT INTO sales_transaction_line 
                (sales_transaction_id, product_variant_id, qty, price_at_sale)
                VALUES 
                (p_sales_transaction_id,v_pv_id,v_qty,v_price);
            -- commit the inventory
            UPDATE product_variant_inventory SET qty = qty - v_qty
                WHERE product_variant_id = v_pv_id;
            RAISE NOTICE 'Success with order % for % units. Sufficient inventory on hand',
                         v_pv_id, v_qty;
            -- add this successful line to the return result
            v_products_ordered := v_products_ordered || ARRAY[[v_pv_id, v_qty]];
            -- In case of an exception in this subtransaction, the latest line will be rolled back
            -- all other lines will be committed, unless there is another error that is not handled
            EXCEPTION -- handle exceptions that pertain to this line of the order
                WHEN check_violation THEN   
                    RAISE NOTICE 'Failure with % for % units. Out of inventory', 
                                v_pv_id, v_qty;
            END;
    END LOOP;     
    RETURN v_products_ordered;
END $$ LANGUAGE PLPGSQL;   


-- Invoke the function defined above, after resetting the inventory level and the specific sales transaction
-- remove all other sales transaction lines from sales transaction to simplify output
DELETE FROM sales_transaction_line WHERE sales_transaction_id = 'east_5316';
-- reset the inventory to create the 'Out of inventory' condition
UPDATE product_variant_inventory set qty = 1 WHERE product_variant_id IN (1,7,8,18,19);

SELECT sf_add_lines_to_sales_order AS committed_lines 
    FROM sf_add_lines_to_sales_order(
        'east_5316', 
        '{{1,1,29.11}, {7,1,15}, {8,1, 32}, {18,3, 58}, {19,1, 5.23}}');

SELECT * FROM inventory_request;    

truncate inventory_request;
SHOW max_worker_processes;


--------
/*

Toy example for pg_backgroundworker

*/

CREATE TABLE background_test (id INTEGER, time TIMESTAMP);

SELECT * FROM background_test;

INSERT INTO background_test (id, time) values (1, CURRENT_TIMESTAMP);
SELECT pg_sleep(5);
INSERT INTO background_test (id, time) values (1, CURRENT_TIMESTAMP);
SELECT pg_sleep(5);
INSERT INTO background_test (id, time) values (1, CURRENT_TIMESTAMP);
SELECT pg_sleep(5);

CREATE OR REPLACE PROCEDURE test_pg_background (p_ctr INTEGER DEFAULT 5)
AS $$
BEGIN
TRUNCATE background_test;
FOR v_i IN 1 .. p_ctr LOOP
    INSERT INTO background_test (id, time) values (v_i, CLOCK_TIMESTAMP());
    PERFORM pg_sleep(5);
END LOOP;
END $$ LANGUAGE PLPGSQL;

CALL test_pg_background(5);
SELECT * FROM background_test;

SELECT * FROM pg_background_result(pg_background_launch('CALL test_pg_background(5)')) AS (result TEXT);

SELECT pg_background_launch('CALL test_pg_background(5)');