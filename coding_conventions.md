Proposed coding conventions


* snake case for all names (database, schemas, tables, views, functions, variables, columns, ...)
* lower case only for all names. Avoid quoted identifiers and spaces in identifiers. All names start with a character of the alphabet or a number
* table names are singular, e.g., 'product' not 'products'
    ** primary key columns (synthetic) are 'id' (preferred) or '<table name>_id'
    ** column names should be meaningful and avoid abbreviations, e.g., 'description', not 'desc'
    ** foreign key references should combine the table name and the column, e.g., 'product_id' referes to the column 'id' in the table 'product'
* temp tables start with tmp_
* views start with 'vw_'
* materialized start with '_mv'
* api functions for create/update/delete use the 'add_/update_/delete_' prefix to the table names, e.g., 'add_product'
* api functions return 
    ** the id of the inserted or updated record (when successful), -1 otherwise
    ** the number of deleted repords (when successful), -1 otherwise
* parameters for procedures and functions start with 'p_'
* database names refer to business functions, e.g., hr or eCommerce
* schemas are used to organize data and procedural aspects
* The schema 'api' is intended for application calls. It contains the CRUD functions and views to access the public data