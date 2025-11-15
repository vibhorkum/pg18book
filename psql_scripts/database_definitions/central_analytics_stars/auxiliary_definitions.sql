/*
================================================================================
  AUXILIARY DATA DEFINITIONS FOR CENTRAL ANALYTICS DATABASE
================================================================================
  OWNER: Superuser
  PURPOSE: Provide additional data structures and functions to support
           the star schemas in central_analytics database.
  Details:
           * auxiliary schema to hold supporting tables and functions
           * us_state table to map state codes to state names and regions
           * functions to parse state and zip code from postal code
           * sales_territory table to map states to sales territories               
================================================================================
*/

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
