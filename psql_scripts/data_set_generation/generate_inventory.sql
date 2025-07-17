/*

--- generate inventory levels for for the us and eu ecommerce setups
--- populates the table inventory.product_inventory with random amounts

*/

DROP PROCEDURE IF EXISTS generate_product_inventory;
CREATE PROCEDURE generate_product_inventory (maxunits INTEGER DEFAULT 500)
AS
$$
DECLARE
    product_record RECORD;
    random_qty INTEGER;
BEGIN
    TRUNCATE product_inventory;
    FOR product_record IN SELECT id FROM product_reference.product 
        LOOP
            random_qty := TRUNC (RANDOM() * maxunits);
            INSERT INTO product_inventory (product_id, qty)
                VALUES (product_record.id, random_qty);
        END LOOP;
END;
$$ LANGUAGE PLPGSQL;