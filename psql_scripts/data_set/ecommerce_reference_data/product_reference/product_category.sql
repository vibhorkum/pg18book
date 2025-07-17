\c ecommerce_reference_data

\echo '--> Inserting data for categories, brands, and products ...'
-- Using OVERRIDING SYSTEM VALUE to control the IDs for predictable testing.
INSERT INTO product_reference.product_category (id, label, description)
    VALUES
        (1, 'Pants', 'long trousers'),
        (2, 'Shirts', 'long sleeve and short sleeve shirts'),
        (3, 'T-Shirts', 'long sleev and short sleeve T-shirts'),
        (4, 'Polos', 'long sleeve and short sleeve polos'),
        (3, 'Blouses', 'long sleeve and short sleeve shirts for women'),
        (4, 'Footwear', 'Dress shoes, sneakers, and sport shoes'),
        (5, 'Jackets', 'Suit coats, leather jackets, sports coats'),
        (6, 'Coats', 'Trench coats, duffle coats')
    ON CONFLICT (id) DO NOTHING;
