/* ----------------------------------------------------------------------------

Audit definitions for eCommerce Sample Application
This requires the extension pgAudit and the role audit.

These are samples for illustration purpose only.

We will define sample audits for the following operations:

All DDL in all databases on the server

eCommerce Reference Data

1) all changes to the product brand and price definitions
2) all function and stored procedure calls

east/west eCommerce Services
1) changes of the inventory information 
2) all function and stored procedure calls

Analytics Service
1) access of any of the analytics queries in central analytics    

*/

\c postgres

ALTER SYSTEM SET pgaudit.role = 'auditor';

ALTER SYSTEM SET audit.pgaudit.log ='ddl';

\c ecommerce_reference_data

-- use object-level auditing for DML on product related tables
GRANT INSERT, UPDATE, DELETE
    ON 
        product.product,
        product.brand,
        product.category,
        product.product_variant,
        product.product_variant_price
    TO auditor;

-- pgAudit does not support object-level auditing for functions or procedures
-- audit all function and procedure calls for this database
ALTER DATABASE SET audit.pgaudit.log ='execute';


\c east_ecommerce_data

-- use object-level auditing for DML on inventory information
GRANT INSERT, UPDATE, DELETE 
    ON inventory.product_variant_inventory;

-- pgAudit does not support object-level auditing for functions or procedures
-- audit all function and procedure calls for this database
ALTER DATABASE SET audit.pgaudit.log ='execute';    

\c west_ecommerce_data
-- use object-level auditing for DML on inventory information
GRANT INSERT, UPDATE, DELETE 
    ON inventory.product_variant_inventory;
-- pgAudit does not support object-level auditing for functions or procedures
-- audit all function and procedure calls for this database
ALTER DATABASE SET audit.pgaudit.log ='execute';    

\c central_analytics

--- to be added when the cenytral analytics API is defined






