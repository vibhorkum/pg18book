-- =================================================================
--  SECTION 4: REFERENCE DATA INSERTION
-- =================================================================

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

INSERT INTO product_reference.product_brand (id, label, description)
    VALUES
        (1, 'Gap', 'The Gap'),
        (2, 'Boss', 'Boss'),
        (3, 'Diesel', 'Diesel'),
        (4, 'Aéropostale',' Aéropostale Inc'),
        (5, 'Levis', 'Levi Strauss & Co'),
        (6, 'Tyrwhitt', 'Charles Tyrwhitt'),
        (7, 'Eton', 'Eton Tayloring'),
        (8, 'Brioni', 'Brioni Tayloring')
    ON CONFLICT (id) DO NOTHING; 

INSERT INTO product_reference.product (id, product_category_id, product_brand_id, label, shortdescription, longdescription, image_filename)
    VALUES
    --- dress shirt Gap
        (1, 2, 1, 'Dress shirt', 
        'Classic mens dress shirt from The Gap —tailored fit, premium cotton, versatile for work or formal wear.',
        '
        Premium Mens Dress Shirt Timeless Style and Unmatched Comfort
        Upgrade your wardrobe with this classic mens dress shirt, designed for sophistication and ease. Made from high quality 100 percent cotton or breathable cotton blend fabric, this shirt offers all day comfort while keeping a sharp, professional look. The tailored fit enhances your silhouette, making it perfect for pairing with suits or wearing solo for business casual style.
        Key features include a button down or spread collar for flexible styling, single button cuffs for a polished finish, and a sturdy button placket built to last. Available in solid colors, subtle stripes, or minimalist patterns, this shirt suits any occasion from office meetings to formal events.
        Built for convenience, this shirt is wrinkle resistant for easy care and machine washable for quick maintenance. The reinforced stitching and durable seams ensure long lasting wear, while the breathable fabric keeps you cool and comfortable all day.
        Sizes range from S to XXL, making this dress shirt a versatile essential for every modern mans wardrobe. Whether dressing for work or a special event, this shirt delivers refined style, exceptional comfort, and reliable quality.
        ',
        'dress_shirt.jpg'
        ),
        --- dress shirt Boss
        (2,2, 2, 'Dress shirt', 
        'Classic mens dress shirt—tailored fit by Boss, premium cotton, versatile for work or formal wear.',
        '
        Premium Mens Dress Shirt Timeless Style and Unmatched Comfort
        Upgrade your wardrobe with this classic mens dress shirt, designed for sophistication and ease. Made from high quality 100 percent cotton or breathable cotton blend fabric, this shirt offers all day comfort while keeping a sharp, professional look. The tailored fit enhances your silhouette, making it perfect for pairing with suits or wearing solo for business casual style.
        Key features include a button down or spread collar for flexible styling, single button cuffs for a polished finish, and a sturdy button placket built to last. Available in solid colors, subtle stripes, or minimalist patterns, this shirt suits any occasion from office meetings to formal events.
        Built for convenience, this shirt is wrinkle resistant for easy care and machine washable for quick maintenance. The reinforced stitching and durable seams ensure long lasting wear, while the breathable fabric keeps you cool and comfortable all day.
        Sizes range from S to XXL, making this dress shirt a versatile essential for every modern mans wardrobe. Whether dressing for work or a special event, this shirt delivers refined style, exceptional comfort, and reliable quality.
        ',
        'dress_shirt.jpg'
        ),
        --- dress shirt Eaton
        (3,2, 7, 'Dress shirt', 
        'Classic mens dress shirt—tailored fit by Eaton, premium cotton, versatile for work or formal wear.',
        '
        Premium Mens Dress Shirt Timeless Style and Unmatched Comfort
        Upgrade your wardrobe with this classic mens dress shirt, designed for sophistication and ease. Made from high quality 100 percent cotton or breathable cotton blend fabric, this shirt offers all day comfort while keeping a sharp, professional look. The tailored fit enhances your silhouette, making it perfect for pairing with suits or wearing solo for business casual style.
        Key features include a button down or spread collar for flexible styling, single button cuffs for a polished finish, and a sturdy button placket built to last. Available in solid colors, subtle stripes, or minimalist patterns, this shirt suits any occasion from office meetings to formal events.
        Built for convenience, this shirt is wrinkle resistant for easy care and machine washable for quick maintenance. The reinforced stitching and durable seams ensure long lasting wear, while the breathable fabric keeps you cool and comfortable all day.
        Sizes range from S to XXL, making this dress shirt a versatile essential for every modern mans wardrobe. Whether dressing for work or a special event, this shirt delivers refined style, exceptional comfort, and reliable quality.
        ',
        'dress_shirt.jpg'
        ),
        --- dress shirt Brioni
        (3,2, 8, 'Dress shirt', 
        'Classic mens dress shirt—tailored fit by Brioni , premium cotton, versatile for work or formal wear.',
        '
        Premium Mens Dress Shirt Timeless Style and Unmatched Comfort
        Upgrade your wardrobe with this classic mens dress shirt, designed for sophistication and ease. Made from high quality 100 percent cotton or breathable cotton blend fabric, this shirt offers all day comfort while keeping a sharp, professional look. The tailored fit enhances your silhouette, making it perfect for pairing with suits or wearing solo for business casual style.
        Key features include a button down or spread collar for flexible styling, single button cuffs for a polished finish, and a sturdy button placket built to last. Available in solid colors, subtle stripes, or minimalist patterns, this shirt suits any occasion from office meetings to formal events.
        Built for convenience, this shirt is wrinkle resistant for easy care and machine washable for quick maintenance. The reinforced stitching and durable seams ensure long lasting wear, while the breathable fabric keeps you cool and comfortable all day.
        Sizes range from S to XXL, making this dress shirt a versatile essential for every modern mans wardrobe. Whether dressing for work or a special event, this shirt delivers refined style, exceptional comfort, and reliable quality.
        ',
        'dress_shirt.jpg'
        ),
        --- Oxford shirt Gap
        (4,2,1, 'Mens Classic Oxford Shirt', 
        'Timeless mens Oxford shirt in 100% cotton from The Gap.', 
        'The Oxford button-down shirt is a cornerstone of classic American style, revered for its 
        effortless versatility, timeless design, and understated elegance. Originating in the early 20th century, 
        it was popularized by Brooks Brothers, who adapted the button-down collar from English polo players to prevent 
        flapping during matches. Made from Oxford cloth—a durable, slightly textured basketweave cotton—this shirt 
        strikes the perfect balance between casual and refined, making it a go-to for both professional and leisure wear.
        The defining feature is its soft-rolling button-down collar, which adds a touch of relaxed sophistication, distinguishing it 
        from dressier formal shirts. Available in a range of essential colors (crisp white, light blue, pale pink) and 
        subtle patterns (university stripes, tattersall checks, or classic solids), it effortlessly pairs with chinos, jeans, 
        blazers, or suits. The slightly thicker Oxford fabric ensures durability while remaining breathable and comfortable for all-day wear.
        Designed with a traditional fit (though slim and modern cuts are also available), it features a button-through front, single 
        chest pocket (optional), and reinforced stitching for longevity. Whether dressed up with a tie and wool trousers or worn 
        casually with rolled sleeves and shorts, the Oxford button-down transitions seamlessly from office to weekend. A favorite 
        among preppy, Ivy League, and business-casual wardrobes, it remains a wardrobe essential—a symbol of enduring style 
        that never goes out of fashion.'
        ,
        'oxford_shirt.jpg'),
        --- Oxford shirt Boss
        (5,2,1, 'Mens Classic Oxford Shirt from Boss', 
        'Timeless mens Oxford shirt in 100% cotton.', 
        'The Oxford button-down shirt is a cornerstone of classic American style, revered for its 
        effortless versatility, timeless design, and understated elegance. Originating in the early 20th century, 
        it was popularized by Brooks Brothers, who adapted the button-down collar from English polo players to prevent 
        flapping during matches. Made from Oxford cloth—a durable, slightly textured basketweave cotton—this shirt 
        strikes the perfect balance between casual and refined, making it a go-to for both professional and leisure wear.
        The defining feature is its soft-rolling button-down collar, which adds a touch of relaxed sophistication, distinguishing it 
        from dressier formal shirts. Available in a range of essential colors (crisp white, light blue, pale pink) and 
        subtle patterns (university stripes, tattersall checks, or classic solids), it effortlessly pairs with chinos, jeans, 
        blazers, or suits. The slightly thicker Oxford fabric ensures durability while remaining breathable and comfortable for all-day wear.
        Designed with a traditional fit (though slim and modern cuts are also available), it features a button-through front, single 
        chest pocket (optional), and reinforced stitching for longevity. Whether dressed up with a tie and wool trousers or worn 
        casually with rolled sleeves and shorts, the Oxford button-down transitions seamlessly from office to weekend. A favorite 
        among preppy, Ivy League, and business-casual wardrobes, it remains a wardrobe essential—a symbol of enduring style 
        that never goes out of fashion.
        ',
        'oxford_shirt.jpg'),
        --- Oxford shirt Boss),
--- Gap T-shirt
        (6, 2, 1, 'T-Shirt', 
        'Short sleeved fitted T-shirt from Gap',
        'Mens T-Shirt: Bold, Edgy, and Unapologetically Cool
        The Mens T-Shirt embodies rebellious spirit and Italian craftsmanship, blending streetwear attitude with premium quality. Designed for the confident, fashion-forward man, it features soft, heavyweight cotton for a structured yet comfortable fit, ensuring durability and effortless style. The signature distressed detailing, bold graphics, or minimalist logo prints make a statement, whether youre rocking it with ripped jeans, tailored joggers, or a leather jacket.
        Cut for a slim or relaxed fit (depending on the style), it offers a modern silhouette that flatters without restricting movement. The reinforced stitching, double-stitched hems, and high-quality screen-printing ensure long-lasting wear, even after repeated washes. From classic crewnecks to edgy oversized cuts, Diesel’s T-shirts cater to diverse tastes—whether you prefer understated monochrome styles or eye-catching, avant-garde designs.
        Perfect for layering under a blazer for a high-low look or wearing solo for casual streetwear vibes, this T-shirt is a versatile staple in any contemporary wardrobe. With its unmistakable  edge, its more than just a basic—its a bold expression of individuality.
        ',
        't-shirt.jpg'),
        --- Oxford shirt Boss),
--- Diesel T-Shirt        
        (7, 2, 1, 'T-Shirt', 
        'Short sleeved fitted T-shirt by Diesel',
        'Mens T-Shirt: Bold, Edgy, and Unapologetically Cool
        The Mens T-Shirt embodies rebellious spirit and Italian craftsmanship, blending streetwear attitude with premium quality. Designed for the confident, fashion-forward man, it features soft, heavyweight cotton for a structured yet comfortable fit, ensuring durability and effortless style. The signature distressed detailing, bold graphics, or minimalist logo prints make a statement, whether youre rocking it with ripped jeans, tailored joggers, or a leather jacket.
        Cut for a slim or relaxed fit (depending on the style), it offers a modern silhouette that flatters without restricting movement. The reinforced stitching, double-stitched hems, and high-quality screen-printing ensure long-lasting wear, even after repeated washes. From classic crewnecks to edgy oversized cuts, Diesel’s T-shirts cater to diverse tastes—whether you prefer understated monochrome styles or eye-catching, avant-garde designs.
        Perfect for layering under a blazer for a high-low look or wearing solo for casual streetwear vibes, this T-shirt is a versatile staple in any contemporary wardrobe. With its unmistakable  edge, its more than just a basic—its a bold expression of individuality.
        ',
        'diesel_t-shirt.jpg'),
        (8, 1, 3, '501 Original Fit Jeans', 
        'The original blue jean since 1873 from Levis.',
        'Levis® 501® Original Fit Jeans – The Icon That Started It All
        Born in 1873 as the worlds first blue jeans, the Levis® 501® Original Fit is a timeless symbol of authenticity, rebellion, and American heritage. Crafted from premium heavyweight denim, these jeans feature a straight-leg silhouette with a classic mid-rise waist and a button-fly closure—staying true to their original workwear roots. The sturdy 100% cotton construction (with select stretch options for added comfort) molds to your body over time, creating a personalized fit thats uniquely yours.
        The 501s signature details—like the iconic red tab, leather-like patch, and reinforced rivets—pay homage to its durable legacy. Versatile enough to dress up with a blazer or keep casual with a vintage tee, theyre a staple in every denim lovers wardrobe. Whether you prefer a rigid, unwashed look that fades beautifully with wear or a pre-washed, lived-in feel, the 501 adapts to your lifestyle while maintaining its rugged charm.
        From cowboys to rockstars, rebels to trendsetters, generations have made the 501 their own. More than just jeans—theyre a cultural icon. Fit note: True to size with a roomy thigh and straight leg opening for a classic, comfortable silhouette.
        ',
        'diesel_t-shirt.jpg'
        ),
 --- Men's leather Jacket by Boss
    (8, 5, 2, 'Leather jacket - casual',
    'Rugged men''s leather jacket—timeless style, premium quality, perfect for any occasion - Boss.',
    '
    Elevate your wardrobe with this premium men''s leather jacket, expertly crafted from high-quality genuine leather for lasting durability 
    and timeless appeal. The classic biker-inspired design features a sleek silhouette with a front zipper closure, notch lapel collar, 
    and multiple functional pockets for everyday convenience. Soft inner lining ensures comfort while the supple leather develops a unique 
    patina over time, personalizing to your wear. Designed for versatility, this jacket transitions effortlessly from casual daytime wear to 
    evening sophistication, pairing perfectly with jeans, tees, or dressier layers. The medium-weight construction makes it ideal for year-round wear, 
    offering just enough warmth without bulk. Reinforced stitching and quality hardware guarantee long-lasting performance, whether youre 
    riding or simply making a style statement. With its tailored yet comfortable fit, this jacket enhances any outfit while maintaining rugged 
    masculinity. A true investment piece, it''s built to age gracefully, becoming more distinctive with each wear. The perfect combination of 
    function and fashion, this leather jacket delivers unmatched confidence and edge for the modern man who values both style and substance in 
    his everyday essentials.
    ','leather_jacket.jpg'),
     --- Men's leather Jacket by Aeropostale
    (8, 5, 4, 'Leather jacket - casual',
    'Stylish men''s leather jacket from Aeropostaletyle, premium quality, perfect for any occasion.',
    '
    Step up your street style with the Aeropostale men''s leather jacket, designed to deliver rugged sophistication with an urban edge. 
    This sleek jacket features a premium faux leather construction that looks and feels luxurious, with a perfectly broken-in vibe 
    from day one. The minimalist biker-inspired design boasts a clean front zipper closure, subtle branding, and a 
    tailored silhouette that flatters every build.
    With its slightly distressed finish and matte black finish, this jacket adds instant cool to any outfit - layer it over hoodies 
    for casual days or pair with dark denim for nightlife appeal. The lightweight construction moves with you while maintaining that 
    coveted leather jacket structure. Inside, a soft lining ensures all-day comfort whether you''re out with friends or running errands.
    Aeropostale''s signature attention to detail shines through in the reinforced stitching, smooth zipper action, 
    and discreet interior pocket. The versatile design transitions effortlessly from season to season, working as well with summer tees as 
    with winter layers. More than just outerwear, this is a style statement that elevates your everyday look with that perfect 
    balance of toughness and refinement.
    ','leather_jacket.jpg'),  
  --- Men's Chinos by Gap
    (9, 1, 1, 'Chinos - casual',   
    'Classic men''s chinos: tailored fit, versatile colors, durable cotton blend, perfect for casual or smart-casual looks.',
    '
    Men''s Chinos - Perfect Fit & Premium Comfort
    Upgrade your wardrobe with our classic men''s chinos, designed for a sharp yet comfortable fit. Crafted from a premium cotton-blend fabric, 
    these chinos offer a soft, breathable feel with just the right amount of stretch for unrestricted movement. The tailored slim or straight fit 
    ensures a modern silhouette—neither too tight nor too loose—while the mid-rise waist provides a polished look that sits comfortably at the hip.
    The durable twill weave resists wrinkles and maintains structure, making these chinos ideal for all-day wear, whether at the office or out for casual 
    outings. Reinforced stitching at stress points ensures long-lasting durability, while the smooth finish adds a refined touch. The fabric''s 
    slight elasticity allows for ease of motion without sagging, so you stay looking sharp from morning to night.
    Available in versatile colors, these chinos pair effortlessly with dress shirts, polos, or casual tees, making them a must-have for any 
    stylish wardrobe. Designed for men who value both comfort and sophistication, these chinos strike the perfect balance between relaxed and refined.
    ','chinos.jpg'), 
 --- Men's Chinos by Boss
    (10, 1, 2, 'Chinos - casual',   
    'Classic men''s chinos: tailored fit, versatile colors, durable cotton blend, perfect for casual or smart-casual looks.',
    '
    Men''s Chinos - Perfect Fit & Premium Comfort
    Upgrade your wardrobe with our classic men''s chinos, designed for a sharp yet comfortable fit. Crafted from a premium cotton-blend fabric, 
    these chinos offer a soft, breathable feel with just the right amount of stretch for unrestricted movement. The tailored slim or straight fit 
    ensures a modern silhouette—neither too tight nor too loose—while the mid-rise waist provides a polished look that sits comfortably at the hip.
    The durable twill weave resists wrinkles and maintains structure, making these chinos ideal for all-day wear, whether at the office or out for casual 
    outings. Reinforced stitching at stress points ensures long-lasting durability, while the smooth finish adds a refined touch. The fabric''s 
    slight elasticity allows for ease of motion without sagging, so you stay looking sharp from morning to night.
    Available in versatile colors, these chinos pair effortlessly with dress shirts, polos, or casual tees, making them a must-have for any 
    stylish wardrobe. Designed for men who value both comfort and sophistication, these chinos strike the perfect balance between relaxed and refined.
    ','chinos.jpg') ,
  --- Sports coat by Boss
    (10, 1, 2, 'Sports coat - business casual',   
    'Tailored men''s sports coat - lightweight, versatile, perfect for business casual elegance.',
    '
    Elevate your business casual wardrobe with this impeccably tailored sports coat, designed for modern professionals who 
    value both style and comfort. Crafted from premium wool-blend fabric with subtle stretch, this jacket offers exceptional breathability 
    and year-round versatility. The refined slim-fit silhouette skims the body without restriction, featuring structured shoulders for a 
    polished look and a slightly tapered waist for flattering proportions.

    The lightweight, wrinkle-resistant material maintains its sharp appearance throughout the workday, while the half-canvas construction 
    ensures proper drape without bulk. Thoughtful details like functioning button cuffs, a notched lapel, and welt pockets enhance the 
    sophisticated aesthetic. The fabric''s natural elasticity allows for comfortable movement, making it ideal for transitioning from 
    office to evening engagements.
    Available in versatile neutral tones, this sports coat pairs effortlessly with dress trousers, chinos, or dark denim. The medium-weight 
    construction provides just enough structure for professional settings while remaining comfortable for all-day wear. 
    Designed for the modern man who demands both style and substance, this jacket delivers the perfect balance of tailored sophistication 
    and relaxed versatility for your business casual rotation.
    ','sports_coat.jpg'), 
     --- Suit coat by Boss
    (11, 1, 2, 'Suit coat - business perfect',   
    'Classic tailored suit coat - premium wool, sharp silhouette, versatile elegance.',
    '
    Refined Versatility: The Perfect Suit Coat for Modern Dressing
    Crafted from premium wool or wool-blend fabrics, this suit coat offers a sharp yet comfortable silhouette with just the right amount of structure. 
    The tailored fit features a gently contoured waist, natural shoulders, and a slightly tapered cut through the body for a polished look that flatters 
    without restricting movement.
    What sets this coat apart is its effortless versatility. While designed to pair perfectly with matching suit trousers for formal occasions, 
    its refined-but-relaxed proportions make it ideal for smart-casual wear too. The medium-weight fabric (180-220g) provides enough body to hold its 
    shape while remaining comfortable all day.
    Pair it with dark blue jeans for an elevated weekend look - the structured shoulders and clean lines create intentional contrast with denim''s casual 
    texture. The fabric''s subtle luster and rich depth of color transition seamlessly from office to evening. Functional sleeve buttons and a well-proportioned 
    lapel width keep it looking appropriate whether you''re dressing up or down.
    For men who want one quality coat that works as hard as they do - equally at home in the boardroom or at a dinner date when paired with jeans and 
    loafers. The wrinkle-resistant weave ensures you''ll always look put together, while the half-canvas construction offers better drape than fused 
    alternatives at this price point.
    ','suit_coat.jpg'), 
 --- Trench coat   
    (12, 1, 2, 'Trench coat - always perfect',   
    'Classic men''s trench coat water resistant timeless style versatile layering piece.',
    '
    Timeless Waterproof Trench Coat Crafted for Maximum Protection and Style
    This classic mens trench coat is constructed from premium waterproof cotton blend fabric treated with advanced water repellent technology to 
    keep you dry in heavy rain. The tightly woven material blocks wind while remaining breathable for all day comfort. Reinforced stitching at 
    stress points and double layered shoulders ensure durability season after season.
    The water resistant finish beads off moisture without compromising the fabrics natural look and feel. A hidden storm flap provides extra 
    protection across the chest while the full length cut shields your legs from downpours. The inner lining features quick drying technology 
    that wicks away moisture when worn over suits or casual layers.
    Designed for urban commuters and travelers this trench coat maintains its crisp silhouette even in wet conditions. The medium weight 
    fabric drapes elegantly without bulk making it ideal for transitional weather. Metal hardware and sturdy buttons withstand repeated 
    use while the adjustable belt allows customized fit over different outfits.
    From business attire to weekend wear this waterproof trench combines practical performance with refined aesthetics. The neutral 
    color options work with any wardrobe while the timeless design ensures years of reliable service. Machine washable for easy care without 
    losing its protective qualities.
    ','trench_coat.jpg'),
    (13, 4, 1, 'Polo shirt',
    'Classic short-sleeve polo shirt by The Gap offering comfort style and value for everyday wear',
    'Classic Short Sleeve Value Polo Shirt The Gap - Premium Fit & Quality Materials
    Upgrade your everyday wardrobe with our short sleeve value polo shirt, designed for comfort, style, and 
    durability. Crafted from high-quality fabric, this polo offers a soft, breathable feel that keeps you cool and 
    comfortable all day. The tailored fit provides a polished look without sacrificing ease of movement, making it 
    perfect for work, casual outings, or weekend wear.
    The reinforced collar and cuffs maintain structure wash after wash, while the moisture-wicking 
    fabric helps you stay fresh in any setting. Available in a range of versatile colors, 
    this polo pairs effortlessly with chinos, jeans, or dress pants for a sharp, put-together appearance.
    Whether youre dressing for the office, a lunch date, or a relaxed day out, this affordable yet premium polo 
    delivers unbeatable value without compromising on fit or fabric quality. Machine washable for easy care, 
    its a must-have staple for any modern wardrobe.',
    'polo_shirt.jpg'),
    (14, 4, 2, 'Polo shirt',
    'Classic short-sleeve polo shirt by Boss offering comfort style and value for everyday wear',
    'Classic Short Sleeve Value Polo Shirt from Boss - Premium Fit & Quality Materials
    Upgrade your everyday wardrobe with our short sleeve value polo shirt, designed for comfort, style, and 
    durability. Crafted from high-quality fabric, this polo offers a soft, breathable feel that keeps you cool and 
    comfortable all day. The tailored fit provides a polished look without sacrificing ease of movement, making it 
    perfect for work, casual outings, or weekend wear.
    The reinforced collar and cuffs maintain structure wash after wash, while the moisture-wicking 
    fabric helps you stay fresh in any setting. Available in a range of versatile colors, 
    this polo pairs effortlessly with chinos, jeans, or dress pants for a sharp, put-together appearance.
    Whether youre dressing for the office, a lunch date, or a relaxed day out, this affordable yet premium polo 
    delivers unbeatable value without compromising on fit or fabric quality. Machine washable for easy care, 
    its a must-have staple for any modern wardrobe.',
    'polo_shirt.jpg')
    ON CONFLICT (id) DO NOTHING;


DROP PROCEDURE IF EXISTS internal.generate_product_prices;

CREATE PROCEDURE internal.generate_product_prices ()
    AS  
        $$
            DECLARE
                product_record RECORD; --- this will be used to iterate over the product records
                product_price NUMERIC;
                price_variance NUMERIC;
                inflation_adjusted_price NUMERIC;
                currency sales_currency; --- ENUM type defined earlier
                geo sales_geo; --- ENUM type defined earlier
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
                        --- create the data entries by iterating over size, color and fit
                        --- this could be optimized for larger commit blocks
 
                        FOREACH validity_range IN ARRAY price_validity_ranges
                            LOOP
                                inflation_adjusted_price := product_price;
                                --- iterate over the product geos
                                FOREACH geo IN ARRAY ENUM_RANGE (null::sales_geo) -- convert enum type to array for iteration
                                    LOOP
                                        IF geo = 'US' THEN currency := 'USD'; ELSE currency := 'EURO'; END IF;
                                        inflation_adjusted_price := inflation_adjusted_price + (inflation_adjusted_price * annual_inflation_rate);
                                        INSERT 
                                            INTO product_reference.product_price (product_id, price, currency, geography, validity, current)
                                            VALUES (
                                                product_record.id,
                                                inflation_adjusted_price + (random() * price_variance * product_price),
                                                currency,
                                                geo, 
                                                validity_range,
                                                false --- by default set price validity as false. The sproc update_current_price_flags() has to be called afterwards
                                                );
                                    END LOOP;
                            END LOOP;
                    END LOOP;
            END;
        $$
    LANGUAGE plpgsql;

\echo '*** Generating variants and prices ***'
CALL internal.generate_product_prices();

\echo '*** Setting current price flags ***'
CALL api.update_current_price_flags();

\echo 'Data set created'

SELECT COUNT(*) AS product_count FROM product_reference.product;
SELECT COUNT(*) AS product_price_count FROM product_reference.product_price;


\echo '*** Script Finished Successfully ***'