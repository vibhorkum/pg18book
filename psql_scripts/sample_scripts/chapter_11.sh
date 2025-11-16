# bash command file to copy the data from east_ecommerce, west_ecommerce, and ecommerce_reference

# each table is truncated before loading to avoid duplicates
# each table is copied using psql's \copy command to stream data between databases

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



echo 'truncating product tables in central_analytics_bcp'
psql -d central_analytics_bcp -c 'TRUNCATE TABLE product.category, product.brand, product.product, product.product_variant, product.product_variant_price CASCADE;'

echo '--> Copying product brand'
psql -d central_analytics -c '\copy product.brand to stdout' | psql -d central_analytics_bcp -c '\copy product.brand from stdin'
echo '--> Copying product category'
psql -d central_analytics -c '\copy product.category to stdout' | psql -d central_analytics_bcp -c '\copy product.category from stdin'
echo '--> Copying product'
psql -d central_analytics -c '\copy product.product to stdout' | psql -d central_analytics_bcp -c '\copy product.product from stdin'
echo '--> Copying product variant'
psql -d central_analytics -c '\copy product.product_variant to stdout' | psql -d central_analytics_bcp -c '\copy product.product_variant from stdin'
echo '--> Copying product variant price'
psql -d central_analytics -c '\copy product.product_variant_price to stdout' | psql -d central_analytics_bcp -c '\copy product.product_variant_price from stdin'

echo 'truncating customer table in central_analytics_bcp'
psql -d central_analytics_bcp -c 'TRUNCATE TABLE customer.customer CASCADE;'
echo '--> Copying customer from east ecommerce'
psql -d east_ecommerce_data -c '\copy customer.customer (id, street_address, city, postal_code, country, origin) to stdout' |\
        psql -d central_analytics_bcp -c '\copy customer.customer (id, street_address, city, postal_code, country, origin) from stdin'
echo '--> Copying customer from west ecommerce'
psql -d west_ecommerce_data -c '\copy customer.customer (id, street_address, city, postal_code, country, origin) to stdout' |\
        psql -d central_analytics_bcp -c '\copy customer.customer (id, street_address, city, postal_code, country, origin) from stdin'

echo 'truncating sales tables in central_analytics_bcp'
psql -d central_analytics_bcp -c 'TRUNCATE TABLE sales.sales_transaction, sales.sales_transaction_line CASCADE;'

echo '--> Copying sales transaction from east ecommerce'
psql -d east_ecommerce_data -c '\copy sales.sales_transaction to stdout' |\
        psql -d central_analytics_bcp -c '\copy sales.sales_transaction from stdin'

echo '--> Copying sales transaction line from east ecommerce'
psql -d east_ecommerce_data -c '\copy sales.sales_transaction_line to stdout' |\
        psql -d central_analytics_bcp -c '\copy sales.sales_transaction_line from stdin'

echo '--> Copying sales transaction from west ecommerce'
psql -d west_ecommerce_data -c '\copy sales.sales_transaction to stdout' |\
        psql -d central_analytics_bcp -c '\copy sales.sales_transaction from stdin'

echo '--> Copying sales transaction line from west ecommerce'
psql -d west_ecommerce_data -c '\copy sales.sales_transaction_line to stdout' |\
        psql -d central_analytics_bcp -c '\copy sales.sales_transaction_line from stdin'        