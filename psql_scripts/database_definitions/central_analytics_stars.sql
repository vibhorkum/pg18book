/* 
===============================================================================
 DESCRIPTION: SQL script file to set up analytics star schemas in the central_analytics
              database.
    Dimensions:
        - date
        - product
        - customer and localtion
    Facts:
        - sales (at the sales_transaction_line level)

 We will show three approaches
    1. View-only approach (except for the date dimension table and the auxiliairy tables for state and territory)
        - uses vo_analytics schema
    2. Materialized view approach with periodic refresh (same as view-only but with better performance)
        - uses mv_analytics schema
    3. Table-based appraoach using insert/update/delete triggers to maintain the fact table
        - uses tt_analytics schema
The auxilliary schema contains supporting tables and functions to help build the dimension tables and views

===============================================================================
*/


/*
================================================================================
 SQL script file to set up analytics star schemas in the central_analytics database.
================================================================================
  OWNER: Superuser
  PURPOSE: Explain how to create a star schemas for reporting
           on the central_analytics database.
  Details:
            * load the auxiliary data and functions into schema 'auxiliary'
                - tables for state and territory codes and names
                - function to parse zip codes and postal codes
            * create three star schemas:
                - view-only schema 'vo_analytics' using views only
                - materialized-view based schema 'mv_analytics'
                - trigger-table based schema 'tt_analytics'
            * each schame has
                - 3 dimensions: date, product, customer location
                - 1 fact table: sales                   
================================================================================
*/

\echo 'Setting up central_analytics star schemas...'
\i database_definitions/central_analytics_stars/auxiliary_definitions.sql
\i database_definitions/central_analytics_stars/vo_analytics.sql
\i database_definitions/central_analytics_stars/mv_analytics.sql
\i database_definitions/central_analytics_stars/tt_analytics.sql

 





