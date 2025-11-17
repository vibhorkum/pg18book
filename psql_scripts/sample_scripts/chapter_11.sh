# bash command file to copy the data from east_ecommerce, west_ecommerce, and ecommerce_reference

# each table is truncated before loading to avoid duplicates
# each table is copied using psql's copy command to stream data between databases

# tables loaded from eCommerce Reference Data into the central_analytics_bcp database:
    # product.category
    # product.brand
    # product.product
    # product.product_variant
    # product.product_variant_price

# tables loaded from east_coast_ecommerce into the central_analytics_bcp database:
    # customer.customer
    # sales.sales_transaction
    # sales.sales_transaction_line

# tables loaded from west_coast_ecommerce into the central_analytics_bcp database:
    # customer.customer
    # sales.sales_transaction
    # sales.sales_transaction_line

# exit on error
set -e

echo 'truncating product tables in central_analytics_bcp'
psql -d central_analytics_bcp -c 'TRUNCATE TABLE product.category, product.brand, product.product, product.product_variant, product.product_variant_price CASCADE;'

echo '--> Copying product brand'
psql -d central_analytics -c 'COPY product.brand TO stdout' | psql -d central_analytics_bcp -c 'COPY product.brand FROM stdin'
echo '--> COPYing product category'
psql -d central_analytics -c 'COPY product.category TO stdout' | psql -d central_analytics_bcp -c 'COPY product.category FROM stdin'
echo '--> Copying product'
psql -d central_analytics -c 'COPY product.product TO stdout' | psql -d central_analytics_bcp -c 'COPY product.product FROM stdin'
echo '--> Copying product variant'
psql -d central_analytics -c 'COPY product.product_variant TO stdout' | psql -d central_analytics_bcp -c 'COPY product.product_variant FROM stdin'
echo '--> Copying product variant price'
psql -d central_analytics -c 'COPY product.product_variant_price TO stdout' | psql -d central_analytics_bcp -c 'COPY product.product_variant_price FROM stdin'

echo 'truncating customer table in central_analytics_bcp'
psql -d central_analytics_bcp -c 'TRUNCATE TABLE customer.customer CASCADE;'
echo '--> Copying customer from east ecommerce'
psql -d east_ecommerce_data -c 'COPY customer.customer (id, street_address, city, postal_code, country, origin) TO stdout' |\
        psql -d central_analytics_bcp -c 'COPY customer.customer (id, street_address, city, postal_code, country, origin) FROM stdin'
echo '--> Copying customer from west ecommerce'
psql -d west_ecommerce_data -c 'COPY customer.customer (id, street_address, city, postal_code, country, origin) TO stdout' |\
        psql -d central_analytics_bcp -c 'COPY customer.customer (id, street_address, city, postal_code, country, origin) FROM stdin'

echo 'truncating sales tables in central_analytics_bcp'
psql -d central_analytics_bcp -c 'TRUNCATE TABLE sales.sales_transaction, sales.sales_transaction_line CASCADE;'

echo '--> Copying sales transaction from east ecommerce'
psql -d east_ecommerce_data -c 'COPY sales.sales_transaction TO stdout' |\
        psql -d central_analytics_bcp -c 'COPY sales.sales_transaction FROM stdin'

echo '--> Copying sales transaction line from east ecommerce'
psql -d east_ecommerce_data -c 'COPY sales.sales_transaction_line TO stdout' |\
        psql -d central_analytics_bcp -c 'COPY sales.sales_transaction_line FROM stdin'

echo '--> Copying sales transaction from west ecommerce'
psql -d west_ecommerce_data -c 'COPY sales.sales_transaction TO stdout' |\
        psql -d central_analytics_bcp -c 'COPY sales.sales_transaction FROM stdin'

echo '--> Copying sales transaction line from west ecommerce'
psql -d west_ecommerce_data -c 'COPY sales.sales_transaction_line TO stdout' |\
        psql -d central_analytics_bcp -c 'COPY sales.sales_transaction_line FROM stdin'    

