
/*

--- Generate the US customer data
--- Postal codes are different, so will probably have a US and and a separate EU generation procedure

*/

\c us_ecommerce_data

SET SEARCH_PATH TO api, product_reference, inventory, us_customer, us_sales; -- make sure path is available in current session

CREATE SCHEMA data_generation;

CREATE OR REPLACE FUNCTION data_generation.generate_random_phone_number (country_prefix TEXT) RETURNS TEXT
AS 
$$
    DECLARE 
        phone_number TEXT;
    BEGIN  
        phone_number := 
            FORMAT(
                '+%s (%s) %s-%s', 
                country_prefix,
                lpad (floor(random() * 1000)::text, 3, '1'), 
                lpad (floor(random() * 1000)::text, 3, '2'),
                lpad (floor(random() * 1000)::text, 3, '3')
                );
    RETURN phone_number;
    END;        
$$  LANGUAGE PLPGSQL;          

CREATE OR REPLACE FUNCTION data_generation.generate_random_phone_numbers(geo TEXT DEFAULT 'US') RETURNS JSONB AS $$
-- random switch between landline (6 digits in groups of 2) and mobile (9 digits in groups of 3)
DECLARE
	country_prefix VARCHAR(4);
BEGIN
    IF geo = 'US' THEN country_prefix := '1'; ELSE country_prefix := '352'; END IF;
	IF RANDOM() > 0.5 THEN --- 50% of cases add a home line
		RETURN jsonb_build_object (
            'home', data_generation.generate_random_phone_number(country_prefix), 
            'mobile', data_generation.generate_random_phone_number(country_prefix)
            );
    ELSE    
        RETURN jsonb_build_object ('mobile', data_generation.generate_random_phone_number(country_prefix));
    END IF; 
END;
$$ LANGUAGE plpgsql;

/* establish a FDW to server localhost:5432 database postgres, schema data_generation
Get only those that have a state and and a city that is not 'Unicorporated'

*/

CREATE EXTENSION  IF NOT EXISTS postgres_fdw;

/*
drop server dlh_server cascade;
*/

CREATE SERVER IF NOT EXISTS dlh_server
        FOREIGN DATA WRAPPER postgres_fdw
        --- this is problematic as the address may change, but localhost does not work
        OPTIONS (host '172.17.0.3', port '5432', dbname 'postgres');

/*
DROP USER MAPPING FOR postgres SERVER dlh_server;
*/
CREATE USER MAPPING  IF NOT EXISTS FOR postgres --- local user
        SERVER dlh_server
        OPTIONS (user 'postgres', password 'postgres');        


CREATE FOREIGN TABLE IF NOT EXISTS data_generation.us_address_starterkit (
    id bigint,
    street_nbr text,
    street_name text,
    county text,
    city text,
    state text,
    zip_code text
)
    SERVER dlh_server
    OPTIONS (schema_name 'data_generation', table_name 'us_address_import');


CREATE OR REPLACE PROCEDURE data_generation.generate_us_customer_data_set (max_nbr INTEGER DEFAULT 500)
AS
$$
DECLARE
    random_first_name VARCHAR(50);
    random_last_name VARCHAR(50);
    random_phone_numbers JSONB;
    random_street_nbr VARCHAR(100);
    random_street_name VARCHAR(100);
    random_city VARCHAR(100);
    random_postal_code VARCHAR(20);
    random_state VARCHAR(50);
BEGIN
    --- create local cache as 'order by' is not being pushed down and random selections take too long
    RAISE NOTICE 'Creating local address cache using 100,000 random addresses';
    CREATE TEMPORARY TABLE IF NOT EXISTS us_address_cache AS 
        SELECT street_name, street_nbr, city, zip_code, state 
            FROM data_generation.us_address_starterkit
            WHERE city NOT ilike 'Unincorporated' and state <> '' ORDER BY RANDOM() LIMIT 100000;
    RAISE NOTICE 'Local address cache created';       
    TRUNCATE customer CASCADE;       
    FOR i IN 1 .. max_nbr  LOOP
        --- not an efficient way to do it, but simple and quick to code
        RAISE NOTICE 'Creating customer %', i; 
        SELECT name INTO random_first_name FROM us_data_seed.us_first_name_seed ORDER BY RANDOM() LIMIT 1; 
        SELECT name INTO random_last_name FROM us_data_seed.us_last_name_seed ORDER BY RANDOM() LIMIT 1; 
        random_phone_numbers := data_generation.generate_random_phone_numbers();
        SELECT street_name, street_nbr, city, zip_code, state 
            INTO random_street_name, random_street_nbr, random_city, random_postal_code, random_state
            FROM us_address_cache
            ORDER BY RANDOM() LIMIT 1;
        INSERT INTO customer (first_name, last_name, phone_numbers, street_address, city, postal_code, country)
            VALUES (random_first_name, random_last_name, random_phone_numbers, 
                FORMAT ('%s, %s',random_street_nbr,random_street_name),  random_city, 
                FORMAT ('%s %s', random_state, random_postal_code), 'US');
    END LOOP;        
END
$$ LANGUAGE PLPGSQL;

CALL data_generation.generate_us_customer_data_set(5000);