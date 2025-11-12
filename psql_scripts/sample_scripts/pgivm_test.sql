-- simplified test of pgivm functionality
-- uses the brand table from the sample ecommerce databases
-- run in central_analytics database

DROP SCHEMA IF EXISTS test_ivm CASCADE;
CREATE SCHEMA test_ivm; 

CREATE EXTENSION IF NOT EXISTS pg_ivm;


DROP TABLE IF EXISTS test_ivm.ivm_brand cascade;

SELECT PGIVM.create_immv(
            'test_ivm.ivm_brand',
            -- using single quotes to avoid conflict with dollar quoting
            'SELECT id, label, description FROM product.brand;');

-- First check the contents of the IVM table and compare it the base table
select pb.*, ib.* from product.brand pb 
LEFT JOIN test_ivm.ivm_brand ib ON pb.id = ib.id;

-- how to test the IVM functionality

-- 1) insert a new brand into the source table product.brand in the database ecommerce_reference_data
--    then check that the IVM table test_ivm.ivm_brand has been updated automatically
--    if the IVM is working correctly, the new brand should appear in the IVM table (but it will not)
select pb.*, ib.* from product.brand pb 
LEFT JOIN test_ivm.ivm_brand ib ON pb.id = ib.id;

-- 2) insert a new brand into the source table product.brand in central_analytics
--    then check that the IVM table test_ivm.ivm_brand has been updated automatically
--    if the IVM is working correctly, the new brand should appear in the IVM table (and it will
select pb.*, ib.* from product.brand pb 
LEFT JOIN test_ivm.ivm_brand ib ON pb.id = ib.id;

-- my conclusion:
-- the IVM is working correctly within a single database, but does not work with logical replication
-- because the changes made via logical replication do not fire the triggers that maintain the IVMs



