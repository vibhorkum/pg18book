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

    