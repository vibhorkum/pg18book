\c ecommerce_reference_data

DROP PROCEDURE IF EXISTS internal.generate_product_prices;

CREATE PROCEDURE internal.generate_product_prices ()
    AS  
        $$
            DECLARE
                product_record RECORD; --- this will be used to iterate over the product records
                product_price NUMERIC;
                price_variance NUMERIC;
                inflation_adjusted_price NUMERIC;
                annual_inflation_rate NUMERIC := 0.03;
                price_validity_ranges DATERANGE[] := ARRAY[
                        '[2024-01-01, 2024-06-30]'::DATERANGE, 
                        '[2024-07-01, 2024-12-31]'::DATERANGE, 
                        '[2025-01-01, 2025-06-30]'::DATERANGE,
                        '[2025-07-01, 2025-12-31]'::DATERANGE,
                        '[2026-01-01, 2026-12-31]'::DATERANGE
                ];
                validity_range DATERANGE;
            BEGIN
                FOR product_record IN SELECT p.id, pc.label as product_category_label
                                            FROM product_reference.product p, product_reference.product_category pc
                                            WHERE p.product_category_id = pc.id
                    LOOP
                        CASE
                            --- choose the value ranges for the attributes and prices
                            WHEN product_record.product_category_label IN ('T-Shirts','Polos', 'Pants')
                                THEN
                                    product_price = 60; --- base price for shirts
                                    price_variance = 0.3; --- 30% price variance assumed
                            WHEN product_record.product_category_label = 'Shirts'
                                THEN    
                                    product_price = 75; --- base price for shirts
                                    price_variance = 0.3; --- 30% price variance assumed
                            WHEN product_record.product_category_label IN ('Jackets', 'Coats')
                                THEN    
                                    product_price = 250; --- base price for shirts
                                    price_variance = 0.15; --- 15% price variance assumed
                            ELSE
                                    product_price = 100; 
                                    price_variance = 0.15; --- 15% price variance assumed
                        END CASE;
                        FOREACH validity_range IN ARRAY price_validity_ranges
                            LOOP
                                inflation_adjusted_price := product_price;
                                INSERT 
                                    INTO product_reference.product_price (product_id, price, validity, current)
                                    VALUES (
                                        product_record.id,
                                        inflation_adjusted_price + (random() * price_variance * product_price),
                                        validity_range,
                                        false --- by default set price validity as false. The sproc update_current_price_flags() has to be called afterwards
                                    );                              
                            END LOOP;
                    END LOOP;
            END;
        $$
    LANGUAGE plpgsql;

\echo '*** Generating variants and prices ***'
CALL internal.generate_product_prices();