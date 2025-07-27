-- =================================================================
--  ENHANCED SAMPLE DATA FOR AI RECOMMENDATIONS
--  PURPOSE: Provides comprehensive test data for AI-powered 
--           product recommendations and similarity search
-- =================================================================

\echo '[SAMPLE DATA] ==> Adding enhanced e-commerce data for AI testing...'

-- =================================================================
--  SECTION 1: ADDITIONAL PRODUCT CATEGORIES AND BRANDS
-- =================================================================

\echo '--> Adding more product categories and brands...'

INSERT INTO product_category (id, label, description)
    VALUES
        (5, 'Accessories', 'Belts, watches, sunglasses, and other accessories'),
        (6, 'Outerwear', 'Jackets, coats, and outdoor clothing'),
        (7, 'Sportswear', 'Athletic and casual sports clothing'),
        (8, 'Dresses', 'Formal and casual dresses for women'),
        (9, 'Swimwear', 'Swimming and beach attire')
    ON CONFLICT (id) DO NOTHING;

INSERT INTO product_brand (id, label, description)
    VALUES
        (6, 'Nike', 'Athletic apparel and footwear'),
        (7, 'Adidas', 'Sports and lifestyle brand'),
        (8, 'Zara', 'Fast fashion and contemporary clothing'),
        (9, 'H&M', 'Affordable fashion for all'),
        (10, 'Uniqlo', 'Japanese casual wear'),
        (11, 'Calvin Klein', 'American fashion house'),
        (12, 'Tommy Hilfiger', 'Premium lifestyle brand'),
        (13, 'Polo Ralph Lauren', 'Classic American style'),
        (14, 'Lacoste', 'French clothing company'),
        (15, 'Under Armour', 'Performance apparel')
    ON CONFLICT (id) DO NOTHING;

-- =================================================================
--  SECTION 2: EXPANDED PRODUCT CATALOG
-- =================================================================

\echo '--> Adding diverse product catalog...'

INSERT INTO product (id, product_category_id, product_brand_id, label, shortdescription, longdescription)
    VALUES
        -- Shirts and Blouses
        (4, 2, 11, 'Calvin Klein Cotton Shirt', 'Premium cotton dress shirt', 
         'Calvin Klein''s signature dress shirt combines modern tailoring with premium cotton for a sophisticated look. Features spread collar, French cuffs, and subtle logo embroidery. Perfect for business meetings or formal occasions. The shirt offers a contemporary fit that''s neither too tight nor too loose, making it ideal for layering under suits or wearing on its own. Machine washable for easy care.'),
        
        (5, 3, 8, 'Zara Silk Blouse', 'Elegant silk blouse for professional wear',
         'This sophisticated Zara silk blouse elevates any professional wardrobe with its luxurious feel and timeless design. Made from 100% silk with a relaxed fit, it features subtle pleating details and mother-of-pearl buttons. The versatile design transitions seamlessly from boardroom to after-work events. Available in classic colors, it pairs beautifully with tailored trousers or pencil skirts.'),
        
        (6, 2, 12, 'Tommy Hilfiger Polo Shirt', 'Classic polo in signature colors',
         'The iconic Tommy Hilfiger polo shirt represents preppy American style at its finest. Crafted from soft cotton pique with the classic three-button placket and ribbed collar and cuffs. Features the signature flag logo and comes in an array of vibrant colors. This versatile piece works equally well for golf, casual Fridays, or weekend outings with friends.'),
        
        -- Pants and Dresses
        (7, 1, 13, 'Ralph Lauren Chinos', 'Premium chino pants in classic fit',
         'Polo Ralph Lauren''s essential chinos combine comfort with refined style. Made from premium cotton twill with a classic straight-leg fit, these versatile pants work for both casual and smart-casual occasions. Features include flat-front styling, belt loops, and the signature pony logo. The timeless design and quality construction make these a wardrobe staple that pairs well with everything from polo shirts to blazers.'),
        
        (8, 8, 8, 'Zara Midi Dress', 'Contemporary midi dress in flowing fabric',
         'This elegant Zara midi dress embodies modern femininity with its flowing silhouette and contemporary design. Made from lightweight fabric that drapes beautifully, it features a fitted bodice and A-line skirt that flatters all body types. The versatile design can be dressed up with heels for evening events or down with sneakers for casual daywear. Perfect for the fashion-conscious woman who values both style and comfort.'),
        
        -- Sportswear
        (9, 7, 6, 'Nike Athletic T-Shirt', 'Performance t-shirt with moisture-wicking technology',
         'Nike''s performance athletic t-shirt is engineered for serious athletes and fitness enthusiasts. Features advanced Dri-FIT technology that wicks moisture away from the skin to keep you dry and comfortable during intense workouts. The lightweight, breathable fabric moves with your body, while flatlock seams reduce chafing. Perfect for running, gym workouts, or any high-intensity activity.'),
        
        (10, 7, 7, 'Adidas Track Pants', 'Classic athletic pants with signature stripes',
         'These iconic Adidas track pants feature the brand''s signature three-stripe design and are perfect for both athletic activities and casual wear. Made from lightweight, breathable fabric with an elastic waistband and ankle cuffs for a comfortable fit. The classic design has been a favorite among athletes and fashion enthusiasts for decades, offering both style and functionality.'),
        
        (11, 7, 15, 'Under Armour Sports Bra', 'High-support sports bra for intense workouts',
         'Under Armour''s high-performance sports bra provides maximum support and comfort during high-intensity workouts. Features compression fit, moisture-wicking fabric, and strategic mesh panels for enhanced breathability. The racerback design allows for full range of motion, while the wide elastic band provides secure fit without rolling. Essential gear for serious female athletes.'),
        
        -- Outerwear
        (12, 6, 10, 'Uniqlo Down Jacket', 'Ultra-light down jacket for winter warmth',
         'Uniqlo''s revolutionary ultra-light down jacket combines exceptional warmth with incredible portability. Filled with premium down and covered in water-repellent fabric, it provides excellent insulation while remaining surprisingly lightweight. The jacket packs down into its own travel pouch, making it perfect for travel or unexpected weather changes. Features include elastic cuffs, adjustable hem, and multiple pockets for convenience.'),
        
        (13, 6, 14, 'Lacoste Windbreaker', 'Classic windbreaker with crocodile logo',
         'The Lacoste windbreaker embodies the brand''s sporting heritage with its lightweight design and water-resistant finish. Perfect for unpredictable weather, this versatile jacket features the iconic crocodile logo, adjustable hood, and zippered pockets. The relaxed fit allows for easy layering over sweaters or hoodies, making it an essential piece for transitional seasons.'),
        
        -- Footwear
        (14, 4, 6, 'Nike Running Shoes', 'Professional running shoes with advanced cushioning',
         'Nike''s latest running shoes feature cutting-edge technology designed to enhance performance and comfort. The advanced cushioning system absorbs impact while providing responsive energy return with each step. Breathable mesh upper keeps feet cool and dry, while the durable rubber outsole provides excellent traction on various surfaces. Perfect for serious runners and casual joggers alike.'),
        
        (15, 4, 7, 'Adidas Lifestyle Sneakers', 'Casual sneakers perfect for everyday wear',
         'These versatile Adidas lifestyle sneakers combine comfort with street-style aesthetics. Featuring the brand''s signature three-stripe design and classic silhouette, they''re perfect for everyday wear. The cushioned midsole provides all-day comfort, while the durable construction ensures long-lasting performance. Available in multiple colorways to match any personal style.'),
        
        -- Accessories
        (16, 5, 11, 'Calvin Klein Leather Belt', 'Premium leather belt with signature buckle',
         'Calvin Klein''s premium leather belt is a timeless accessory that completes any sophisticated look. Made from genuine leather with the brand''s signature rectangular buckle, it adds a touch of elegance to both business and casual attire. The classic design and quality construction ensure this belt will remain a wardrobe staple for years to come.'),
        
        (17, 5, 12, 'Tommy Hilfiger Watch', 'Classic analog watch with leather strap',
         'The Tommy Hilfiger classic watch combines traditional timekeeping with contemporary style. Features a stainless steel case, analog display, and genuine leather strap for comfort and durability. The clean, minimalist design makes it suitable for both professional and casual settings. Water-resistant construction ensures reliable performance in various conditions.')
    ON CONFLICT (id) DO NOTHING;

-- =================================================================
--  SECTION 3: PRODUCT VARIANTS WITH DIVERSE ATTRIBUTES
-- =================================================================

\echo '--> Adding product variants with detailed attributes...'

INSERT INTO product_variant (id, product_id, attributes, upc)
    VALUES
        -- Calvin Klein Shirt variants
        (4, 4, '{"color": "white", "size": "M", "collar": "spread", "fit": "slim"}', '123456789018'),
        (5, 4, '{"color": "light blue", "size": "L", "collar": "spread", "fit": "slim"}', '123456789019'),
        (6, 4, '{"color": "white", "size": "XL", "collar": "spread", "fit": "regular"}', '123456789020'),
        
        -- Zara Silk Blouse variants
        (7, 5, '{"color": "ivory", "size": "S", "material": "silk", "style": "professional"}', '123456789021'),
        (8, 5, '{"color": "navy", "size": "M", "material": "silk", "style": "professional"}', '123456789022'),
        (9, 5, '{"color": "black", "size": "L", "material": "silk", "style": "professional"}', '123456789023'),
        
        -- Tommy Hilfiger Polo variants
        (10, 6, '{"color": "navy", "size": "M", "style": "classic polo", "logo": "flag"}', '123456789024'),
        (11, 6, '{"color": "white", "size": "L", "style": "classic polo", "logo": "flag"}', '123456789025'),
        (12, 6, '{"color": "red", "size": "XL", "style": "classic polo", "logo": "flag"}', '123456789026'),
        
        -- Ralph Lauren Chinos variants
        (13, 7, '{"color": "khaki", "size": "32x32", "fit": "classic", "material": "cotton twill"}', '123456789027'),
        (14, 7, '{"color": "navy", "size": "34x32", "fit": "classic", "material": "cotton twill"}', '123456789028'),
        (15, 7, '{"color": "olive", "size": "36x32", "fit": "classic", "material": "cotton twill"}', '123456789029'),
        
        -- Zara Midi Dress variants
        (16, 8, '{"color": "black", "size": "S", "length": "midi", "style": "A-line"}', '123456789030'),
        (17, 8, '{"color": "navy", "size": "M", "length": "midi", "style": "A-line"}', '123456789031'),
        (18, 8, '{"color": "burgundy", "size": "L", "length": "midi", "style": "A-line"}', '123456789032'),
        
        -- Nike Athletic T-Shirt variants
        (19, 9, '{"color": "black", "size": "M", "technology": "Dri-FIT", "fit": "athletic"}', '123456789033'),
        (20, 9, '{"color": "grey", "size": "L", "technology": "Dri-FIT", "fit": "athletic"}', '123456789034'),
        (21, 9, '{"color": "blue", "size": "XL", "technology": "Dri-FIT", "fit": "athletic"}', '123456789035'),
        
        -- Adidas Track Pants variants
        (22, 10, '{"color": "black", "size": "M", "stripe": "white", "style": "classic"}', '123456789036'),
        (23, 10, '{"color": "navy", "size": "L", "stripe": "white", "style": "classic"}', '123456789037'),
        (24, 10, '{"color": "grey", "size": "XL", "stripe": "black", "style": "classic"}', '123456789038'),
        
        -- Under Armour Sports Bra variants
        (25, 11, '{"color": "black", "size": "S", "support": "high", "style": "racerback"}', '123456789039'),
        (26, 11, '{"color": "pink", "size": "M", "support": "high", "style": "racerback"}', '123456789040'),
        (27, 11, '{"color": "grey", "size": "L", "support": "high", "style": "racerback"}', '123456789041'),
        
        -- Uniqlo Down Jacket variants
        (28, 12, '{"color": "black", "size": "M", "fill": "down", "weight": "ultra-light"}', '123456789042'),
        (29, 12, '{"color": "navy", "size": "L", "fill": "down", "weight": "ultra-light"}', '123456789043'),
        (30, 12, '{"color": "grey", "size": "XL", "fill": "down", "weight": "ultra-light"}', '123456789044'),
        
        -- Lacoste Windbreaker variants
        (31, 13, '{"color": "navy", "size": "M", "style": "windbreaker", "logo": "crocodile"}', '123456789045'),
        (32, 13, '{"color": "white", "size": "L", "style": "windbreaker", "logo": "crocodile"}', '123456789046'),
        (33, 13, '{"color": "green", "size": "XL", "style": "windbreaker", "logo": "crocodile"}', '123456789047'),
        
        -- Nike Running Shoes variants
        (34, 14, '{"color": "black", "size": "9", "type": "running", "technology": "Air Max"}', '123456789048'),
        (35, 14, '{"color": "white", "size": "10", "type": "running", "technology": "Air Max"}', '123456789049'),
        (36, 14, '{"color": "blue", "size": "11", "type": "running", "technology": "Air Max"}', '123456789050'),
        
        -- Adidas Lifestyle Sneakers variants
        (37, 15, '{"color": "white", "size": "9", "style": "lifestyle", "stripes": "black"}', '123456789051'),
        (38, 15, '{"color": "black", "size": "10", "style": "lifestyle", "stripes": "white"}', '123456789052'),
        (39, 15, '{"color": "grey", "size": "11", "style": "lifestyle", "stripes": "navy"}', '123456789053'),
        
        -- Calvin Klein Belt variants
        (40, 16, '{"color": "black", "size": "32", "material": "leather", "buckle": "rectangular"}', '123456789054'),
        (41, 16, '{"color": "brown", "size": "34", "material": "leather", "buckle": "rectangular"}', '123456789055'),
        (42, 16, '{"color": "black", "size": "36", "material": "leather", "buckle": "rectangular"}', '123456789056'),
        
        -- Tommy Hilfiger Watch variants
        (43, 17, '{"color": "black", "strap": "leather", "style": "analog", "case": "steel"}', '123456789057'),
        (44, 17, '{"color": "brown", "strap": "leather", "style": "analog", "case": "steel"}', '123456789058'),
        (45, 17, '{"color": "navy", "strap": "leather", "style": "analog", "case": "steel"}', '123456789059')
    ON CONFLICT (upc) DO NOTHING;

-- =================================================================
--  SECTION 4: EXPANDED PRICING DATA
-- =================================================================

\echo '--> Adding comprehensive pricing data...'

INSERT INTO product_variant_price (id, product_variant_id, price, currency, geography, validity, current)
    VALUES
        -- Calvin Klein Shirt prices
        (5, 4, 89.99, 'USD', 'US', '[2025-01-01,)', true),
        (6, 4, 76.50, 'EURO', 'EU', '[2025-01-01,)', true),
        (7, 5, 89.99, 'USD', 'US', '[2025-01-01,)', true),
        (8, 5, 76.50, 'EURO', 'EU', '[2025-01-01,)', true),
        (9, 6, 94.99, 'USD', 'US', '[2025-01-01,)', true),
        (10, 6, 81.50, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Zara Silk Blouse prices
        (11, 7, 159.99, 'USD', 'US', '[2025-01-01,)', true),
        (12, 7, 139.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (13, 8, 159.99, 'USD', 'US', '[2025-01-01,)', true),
        (14, 8, 139.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (15, 9, 159.99, 'USD', 'US', '[2025-01-01,)', true),
        (16, 9, 139.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Tommy Hilfiger Polo prices
        (17, 10, 69.99, 'USD', 'US', '[2025-01-01,)', true),
        (18, 10, 59.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (19, 11, 69.99, 'USD', 'US', '[2025-01-01,)', true),
        (20, 11, 59.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (21, 12, 69.99, 'USD', 'US', '[2025-01-01,)', true),
        (22, 12, 59.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Ralph Lauren Chinos prices
        (23, 13, 125.00, 'USD', 'US', '[2025-01-01,)', true),
        (24, 13, 110.00, 'EURO', 'EU', '[2025-01-01,)', true),
        (25, 14, 125.00, 'USD', 'US', '[2025-01-01,)', true),
        (26, 14, 110.00, 'EURO', 'EU', '[2025-01-01,)', true),
        (27, 15, 125.00, 'USD', 'US', '[2025-01-01,)', true),
        (28, 15, 110.00, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Zara Midi Dress prices
        (29, 16, 79.99, 'USD', 'US', '[2025-01-01,)', true),
        (30, 16, 69.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (31, 17, 79.99, 'USD', 'US', '[2025-01-01,)', true),
        (32, 17, 69.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (33, 18, 79.99, 'USD', 'US', '[2025-01-01,)', true),
        (34, 18, 69.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Nike Athletic T-Shirt prices
        (35, 19, 34.99, 'USD', 'US', '[2025-01-01,)', true),
        (36, 19, 29.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (37, 20, 34.99, 'USD', 'US', '[2025-01-01,)', true),
        (38, 20, 29.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (39, 21, 34.99, 'USD', 'US', '[2025-01-01,)', true),
        (40, 21, 29.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Adidas Track Pants prices
        (41, 22, 59.99, 'USD', 'US', '[2025-01-01,)', true),
        (42, 22, 52.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (43, 23, 59.99, 'USD', 'US', '[2025-01-01,)', true),
        (44, 23, 52.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (45, 24, 59.99, 'USD', 'US', '[2025-01-01,)', true),
        (46, 24, 52.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Under Armour Sports Bra prices
        (47, 25, 49.99, 'USD', 'US', '[2025-01-01,)', true),
        (48, 25, 44.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (49, 26, 49.99, 'USD', 'US', '[2025-01-01,)', true),
        (50, 26, 44.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (51, 27, 49.99, 'USD', 'US', '[2025-01-01,)', true),
        (52, 27, 44.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Uniqlo Down Jacket prices
        (53, 28, 99.90, 'USD', 'US', '[2025-01-01,)', true),
        (54, 28, 89.90, 'EURO', 'EU', '[2025-01-01,)', true),
        (55, 29, 99.90, 'USD', 'US', '[2025-01-01,)', true),
        (56, 29, 89.90, 'EURO', 'EU', '[2025-01-01,)', true),
        (57, 30, 99.90, 'USD', 'US', '[2025-01-01,)', true),
        (58, 30, 89.90, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Lacoste Windbreaker prices
        (59, 31, 149.99, 'USD', 'US', '[2025-01-01,)', true),
        (60, 31, 129.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (61, 32, 149.99, 'USD', 'US', '[2025-01-01,)', true),
        (62, 32, 129.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (63, 33, 149.99, 'USD', 'US', '[2025-01-01,)', true),
        (64, 33, 129.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Nike Running Shoes prices
        (65, 34, 129.99, 'USD', 'US', '[2025-01-01,)', true),
        (66, 34, 119.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (67, 35, 129.99, 'USD', 'US', '[2025-01-01,)', true),
        (68, 35, 119.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (69, 36, 129.99, 'USD', 'US', '[2025-01-01,)', true),
        (70, 36, 119.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Adidas Lifestyle Sneakers prices
        (71, 37, 89.99, 'USD', 'US', '[2025-01-01,)', true),
        (72, 37, 79.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (73, 38, 89.99, 'USD', 'US', '[2025-01-01,)', true),
        (74, 38, 79.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (75, 39, 89.99, 'USD', 'US', '[2025-01-01,)', true),
        (76, 39, 79.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Calvin Klein Belt prices
        (77, 40, 59.99, 'USD', 'US', '[2025-01-01,)', true),
        (78, 40, 52.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (79, 41, 59.99, 'USD', 'US', '[2025-01-01,)', true),
        (80, 41, 52.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (81, 42, 59.99, 'USD', 'US', '[2025-01-01,)', true),
        (82, 42, 52.99, 'EURO', 'EU', '[2025-01-01,)', true),
        
        -- Tommy Hilfiger Watch prices
        (83, 43, 149.99, 'USD', 'US', '[2025-01-01,)', true),
        (84, 43, 129.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (85, 44, 149.99, 'USD', 'US', '[2025-01-01,)', true),
        (86, 44, 129.99, 'EURO', 'EU', '[2025-01-01,)', true),
        (87, 45, 149.99, 'USD', 'US', '[2025-01-01,)', true),
        (88, 45, 129.99, 'EURO', 'EU', '[2025-01-01,)', true)
    ON CONFLICT (id) DO NOTHING;

\echo '[SAMPLE DATA] ==> Enhanced product catalog created successfully!'
\echo '==> Added:'
\echo '    - 5 new product categories'
\echo '    - 10 new brands'
\echo '    - 14 new products with detailed descriptions'
\echo '    - 42 new product variants with rich attributes'
\echo '    - 84 new price entries across US and EU markets'