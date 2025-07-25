
\set ON_ERROR_STOP on

\c eu_ecommerce_data

CREATE SCHEMA IF  NOT EXISTS data_generation;

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
    IF geo = 'US' THEN country_prefix := '1'; ELSE country_prefix := TRUNC(RANDOM()*400)::TEXT; END IF;
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

TRUNCATE eu_customer.customer CASCADE;

INSERT INTO eu_customer.customer (id, first_name, last_name, phone_numbers, street_address, postal_code, city, country)
WITH country_data AS (
    SELECT 
        country,
        first_names,
        last_names,
        cities
    FROM (VALUES
        ('Germany', ARRAY['Max','Emma','Ben','Hannah','Paul','Sophie','Luca','Marie','Finn','Lea', 'Johan','Karin','Maria', 'Erna', 'Lilli', 'Helga', 'Erika'],
              ARRAY['Müller','Schmidt','Schneider','Fischer','Weber','Meyer','Wagner','Becker','Schulz','Hoffmann'],
              ARRAY['Berlin','Hamburg','Munich','Cologne','Frankfurt','Stuttgart','Düsseldorf','Dortmund','Essen','Leipzig']),
        ('France', ARRAY['Jean','Marie','Pierre','Julie','Thomas','Camille','Nicolas','Sarah','Alexandre','Laura', 'Albert', 'Laurent', 'Paul', 'Erique'],
              ARRAY['Martin','Bernard','Dubois','Thomas','Robert','Richard','Petit','Durand','Leroy','Moreau'],
              ARRAY['Paris','Marseille','Lyon','Toulouse','Nice','Nantes','Strasbourg','Montpellier','Bordeaux','Lille']),
        -- Add more country-specific patterns as needed
        ('Italy', ARRAY['Luca','Sofia','Francesco','Aurora','Alessandro','Giulia','Leonardo','Ginevra','Mattia','Alice'],
              ARRAY['Rossi','Russo','Ferrari','Esposito','Bianchi','Romano','Colombo','Bruno','Ricci','Marino'],
              ARRAY['Rome','Milan','Naples','Turin','Palermo','Genoa','Bologna','Florence','Bari','Catania']),
        ('Spain', ARRAY['Hugo','Lucia','Martin','Maria','Daniel','Paula','Pablo','Sofia','Alejandro','Valeria'],
              ARRAY['Garcia','Rodriguez','Gonzalez','Fernandez','Lopez','Martinez','Sanchez','Perez','Gomez','Martin'],
              ARRAY['Madrid','Barcelona','Valencia','Seville','Zaragoza','Malaga','Murcia','Palma','Bilbao','Alicante'])
        -- Add more countries as needed
    ) AS t(country, first_names, last_names, cities)
)
SELECT 
    UUIDV7(),
    first_names[1 + floor(random() * array_length(first_names, 1))]::text,
    last_names[1 + floor(random() * array_length(last_names, 1))]::text,
    data_generation.generate_random_phone_numbers('EU'), 
    (floor(random() * 100 + 1)::text || ' ' || 
    CASE WHEN random() < 0.3 THEN street_types[1 + floor(random() * array_length(street_types, 1))]::text || ' ' ELSE '' END ||
    street_names[1 + floor(random() * array_length(street_names, 1))]::text),
    substring(md5(random()::text), 5, 10),
    cities[1 + floor(random() * array_length(cities, 1))]::text,
    country
FROM 
    country_data,
    (SELECT ARRAY['Main','Oak','Pine','Maple','Cedar','Elm','View','Hill','Lake','Park'] AS street_names) AS sn,
    (SELECT ARRAY['Street','Avenue','Boulevard','Road','Lane','Drive','Court','Place','Terrace','Way'] AS street_types) AS st
CROSS JOIN generate_series(1, 2000) -- Adjust based on number of countries to get ~500 total
ORDER BY random()
LIMIT 5000;

DROP FUNCTION data_generation.generate_random_phone_number;
DROP FUNCTION data_generation.generate_random_phone_numbers;

DROP SCHEMA data_generation;

select count(*) from eu_customer.customer;
select * from eu_customer.customer;