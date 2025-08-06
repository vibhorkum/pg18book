

--- this role will be used to create the databases

DROP ROLE IF EXISTS master_dba;
CREATE ROLE master_dba WITH
    CREATEDB
    CREATEROLE
    LOGIN
    PASSWORD 'postgres';

--- this role will be used to create, schemas, tables, procedures and functions
--- master_dba will assign the create role to the database after creating
DROP ROLE IF EXISTS application_dba;
CREATE ROLE application_dba WITH
    LOGIN
    PASSWORD 'postgres';

--- this role will be used to create and run the replications
DROP ROLE IF EXISTS replication_dba;
CREATE ROLE replication_dba WITH
    LOGIN
    PASSWORD 'postgres';    

/* 
\c postgres postgres

DROP ROLE IF EXISTS master_dba;
CREATE ROLE master_dba WITH
    CREATEDB
    CREATEROLE
    INHERIT;

DROP ROLE IF EXISTS master_dba1;
CREATE ROLE master_dba1 WITH
    LOGIN
    PASSWORD 'postgres'
    IN ROLE master_dba;

\c postgres master_dba1

CREATE DATABASE testdb1;
*/