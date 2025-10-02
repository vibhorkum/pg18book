-- select a  customer based on random last_name and random    first_name
SELECT * FROM east_customer.customer
WHERE last_name = (
    SELECT last_name FROM east_customer.customer
    ORDER BY RANDOM()
    LIMIT 1
)
AND first_name = (
    SELECT first_name FROM east_customer.customer
    ORDER BY RANDOM()
    LIMIT 1
)
LIMIT 1;