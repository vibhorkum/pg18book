# run with ./pgbench-command.sh
# all commands are defined in the files in this directory and call procedures defined in /sample_scripts/chapter_8.sql files

# vacuum full firstly the entire database with 5 parallel jobs
vacuumdb -h localhost -p 5432 --dbname=east_ecommerce_data --full --verbose --jobs 5

# the commands run against database east_ecommerce_data on localhost port 5432
# 10 concurrent connections for 60 seconds
# progress report every 5 seconds
# the files are run in the order specified, with the @n indicating the relative frequency of execution
pgbench  -h localhost -p 5432 \
-d east_ecommerce_data \
-c 10 -n -T 1200  -P 5 \
-f gen-inventory.sql@6 \
-f gen-sales-transactions.sql@4 \
-f delete-sales-transaction-line.sql@1 \
-f update-customer.sql@4 \
-f select-customer.sql@5
