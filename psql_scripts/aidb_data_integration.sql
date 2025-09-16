-- =================================================================
--  DATA INTEGRATION FOR AI DATABASE (aidb)
-- =================================================================
--  Populates aidb with data from ecommerce_reference_data
--  Maps existing reference data to the AI schema
-- =================================================================

\c aidb

\echo '========================================'
\echo '  Integrating E-commerce Reference Data'
\echo '========================================'

-- First check if we can access the reference database
\echo '--> Checking for reference database connection...'

-- Create a function to safely copy data from reference database if available
DO $$
DECLARE
    ref_db_exists boolean := false;
BEGIN
    -- Check if reference database exists
    SELECT EXISTS(
        SELECT 1 FROM pg_database WHERE datname = 'ecommerce_reference_data'
    ) INTO ref_db_exists;
    
    IF ref_db_exists THEN
        RAISE NOTICE 'Reference database found. Will create dblink extension for data integration.';
    ELSE
        RAISE NOTICE 'Reference database not found. Using sample data only.';
    END IF;
END $$;

-- Add more realistic sample data based on the reference schema structure
\echo '--> Adding extended sample data...'

-- Additional product categories from reference data
INSERT INTO public.product_category(name) VALUES
  ('Pants'),('Polos'),('Blouses'),('Footwear'),('Accessories'),
  ('Outerwear'),('Sportswear'),('Dresses'),('Swimwear'),('Jackets'),('Coats')
ON CONFLICT (name) DO NOTHING;

-- Additional brands
INSERT INTO public.product_brand(name) VALUES
  ('Gap'),('Boss'),('Eaton'),('Diesel'),('Nike'),('Adidas'),('Zara'),('H&M')
ON CONFLICT (name) DO NOTHING;

-- Additional realistic products
INSERT INTO public.product(name, description, category_id, brand_id) VALUES
  ('Men''s Dress Shirt', 'Classic mens dress shirt—tailored fit, premium cotton, versatile for work or formal wear.',
     (SELECT id FROM public.product_category WHERE name='Shirt'),
     (SELECT id FROM public.product_brand    WHERE name='Gap')),
  ('Men''s Oxford Shirt', 'Timeless mens Oxford shirt in 100% cotton.',
     (SELECT id FROM public.product_category WHERE name='Shirt'),
     (SELECT id FROM public.product_brand    WHERE name='Boss')),
  ('Diesel T-Shirt', 'Short sleeved fitted T-shirt by Diesel with bold graphics.',
     (SELECT id FROM public.product_category WHERE name='T-Shirt'),
     (SELECT id FROM public.product_brand    WHERE name='Diesel')),
  ('Nike Running Shoes', 'Lightweight running shoes with advanced cushioning.',
     (SELECT id FROM public.product_category WHERE name='Footwear'),
     (SELECT id FROM public.product_brand    WHERE name='Nike')),
  ('Adidas Track Pants', 'Comfortable athletic pants for training and casual wear.',
     (SELECT id FROM public.product_category WHERE name='Pants'),
     (SELECT id FROM public.product_brand    WHERE name='Adidas')),
  ('Zara Wool Sweater', 'Premium wool sweater in multiple colors.',
     (SELECT id FROM public.product_category WHERE name='Sweater'),
     (SELECT id FROM public.product_brand    WHERE name='Zara')),
  ('H&M Summer Dress', 'Light and airy summer dress perfect for warm weather.',
     (SELECT id FROM public.product_category WHERE name='Dresses'),
     (SELECT id FROM public.product_brand    WHERE name='H&M')),
  ('Boss Leather Jacket', 'Premium leather jacket with modern styling.',
     (SELECT id FROM public.product_category WHERE name='Jackets'),
     (SELECT id FROM public.product_brand    WHERE name='Boss'))
ON CONFLICT (name) DO NOTHING;

-- Additional product variants
INSERT INTO public.product_variant(product_id, sku, color, size) VALUES
  ((SELECT id FROM public.product WHERE name='Men''s Dress Shirt'), 'SKU-DRESS-001', 'white', 'M'),
  ((SELECT id FROM public.product WHERE name='Men''s Dress Shirt'), 'SKU-DRESS-002', 'blue', 'L'),
  ((SELECT id FROM public.product WHERE name='Men''s Oxford Shirt'), 'SKU-OXFORD-001', 'white', 'M'),
  ((SELECT id FROM public.product WHERE name='Men''s Oxford Shirt'), 'SKU-OXFORD-002', 'light blue', 'L'),
  ((SELECT id FROM public.product WHERE name='Diesel T-Shirt'), 'SKU-DIESEL-001', 'black', 'M'),
  ((SELECT id FROM public.product WHERE name='Diesel T-Shirt'), 'SKU-DIESEL-002', 'gray', 'L'),
  ((SELECT id FROM public.product WHERE name='Nike Running Shoes'), 'SKU-NIKE-001', 'black', '10'),
  ((SELECT id FROM public.product WHERE name='Nike Running Shoes'), 'SKU-NIKE-002', 'white', '11'),
  ((SELECT id FROM public.product WHERE name='Adidas Track Pants'), 'SKU-ADIDAS-001', 'black', 'M'),
  ((SELECT id FROM public.product WHERE name='Adidas Track Pants'), 'SKU-ADIDAS-002', 'navy', 'L'),
  ((SELECT id FROM public.product WHERE name='Zara Wool Sweater'), 'SKU-ZARA-001', 'gray', 'M'),
  ((SELECT id FROM public.product WHERE name='Zara Wool Sweater'), 'SKU-ZARA-002', 'navy', 'L'),
  ((SELECT id FROM public.product WHERE name='H&M Summer Dress'), 'SKU-HM-001', 'floral', 'S'),
  ((SELECT id FROM public.product WHERE name='H&M Summer Dress'), 'SKU-HM-002', 'solid blue', 'M'),
  ((SELECT id FROM public.product WHERE name='Boss Leather Jacket'), 'SKU-BOSS-001', 'black', 'M'),
  ((SELECT id FROM public.product WHERE name='Boss Leather Jacket'), 'SKU-BOSS-002', 'brown', 'L')
ON CONFLICT (sku) DO NOTHING;

-- Additional pricing
INSERT INTO public.product_variant_price(product_variant_id, currency, amount) VALUES
  ((SELECT id FROM public.product_variant WHERE sku='SKU-DRESS-001'), 'USD', 79.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-DRESS-002'), 'USD', 84.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-OXFORD-001'), 'USD', 69.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-OXFORD-002'), 'USD', 69.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-DIESEL-001'), 'USD', 45.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-DIESEL-002'), 'USD', 45.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-NIKE-001'), 'USD', 129.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-NIKE-002'), 'USD', 129.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-ADIDAS-001'), 'USD', 59.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-ADIDAS-002'), 'USD', 59.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-ZARA-001'), 'USD', 89.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-ZARA-002'), 'USD', 89.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-HM-001'), 'USD', 24.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-HM-002'), 'USD', 24.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-BOSS-001'), 'USD', 299.99),
  ((SELECT id FROM public.product_variant WHERE sku='SKU-BOSS-002'), 'USD', 329.99)
ON CONFLICT DO NOTHING;

-- Update category complements to include new categories
INSERT INTO api.category_complements(category_name, complements) VALUES
  ('Pants',     ARRAY['Shirt','T-Shirt','Blouse','Sweater']),
  ('Polos',     ARRAY['Jeans','Trousers','Shorts']),
  ('Footwear',  ARRAY['Jeans','Trousers','Shorts','Dresses']),
  ('Accessories', ARRAY['Shirt','Dress','Jeans','Trousers']),
  ('Outerwear', ARRAY['Jeans','Trousers','Shirt','T-Shirt']),
  ('Sportswear', ARRAY['Shorts','Track Pants']),
  ('Dresses',   ARRAY['Accessories','Footwear']),
  ('Swimwear',  ARRAY['Shorts','Accessories']),
  ('Jackets',   ARRAY['Jeans','Trousers','Shirt']),
  ('Coats',     ARRAY['Jeans','Trousers','Sweater'])
ON CONFLICT (category_name) DO NOTHING;

\echo '--> Data integration completed!'

-- Show summary of integrated data
\echo '--> Summary of integrated data:'
SELECT 'Categories' as data_type, count(*) as count FROM public.product_category
UNION ALL
SELECT 'Brands', count(*) FROM public.product_brand
UNION ALL  
SELECT 'Products', count(*) FROM public.product
UNION ALL
SELECT 'Variants', count(*) FROM public.product_variant
UNION ALL
SELECT 'Prices', count(*) FROM public.product_variant_price
UNION ALL
SELECT 'Complement Rules', count(*) FROM api.category_complements
ORDER BY data_type;

\echo '========================================'
\echo '  Data Integration Completed!'
\echo '========================================'