/* 
===============================================================================
 FILE: chapter_10.sql
 */

-- test the star schemas in the central_analytics database  

-- test the view-only analytics schema  
SELECT COUNT(*) AS fact_sales_rows FROM vo_analytics.vw_fact_sales;    
SELECT SUM(sales_amount) AS total_sales_amount FROM vo_analytics.vw_fact_sales; 

SELECT state_name, COALESCE(city, 'Total'), SUM(sales_amount) AS total_sales_amount 
    FROM vo_analytics.vw_fact_sales
    JOIN vo_analytics.vw_dim_customer_location AS cl ON vw_fact_sales.customer_id = cl.customer_id
    JOIN vo_analytics.vw_dim_date AS dd ON vw_fact_sales.date = dd.date_key
    WHERE year = 2024
    GROUP BY ROLLUP (country, state_name, city)
    ORDER BY state_name, city ASC NULLS LAST;


-- test the materialized view analytics schema  

-- refresh the materialized views
REFRESH MATERIALIZED VIEW mv_analytics.mv_fact_sales;
REFRESH MATERIALIZED VIEW mv_analytics.mv_dim_product;
REFRESH MATERIALIZED VIEW mv_analytics.mv_dim_customer_location;
REFRESH MATERIALIZED VIEW mv_analytics.mv_dim_date;    


SELECT COUNT(*) AS fact_sales_rows FROM mv_analytics.mv_fact_sales;    
SELECT SUM(sales_amount) AS total_sales_amount FROM mv_analytics.mv_fact_sales; 
SELECT state_name, COALESCE(city, 'Total'), SUM(sales_amount) AS total_sales_amount 
    FROM mv_analytics.mv_fact_sales
    JOIN mv_analytics.mv_dim_customer_location AS cl ON mv_fact_sales.customer_id = cl.customer_id
    JOIN mv_analytics.mv_dim_date AS dd ON mv_fact_sales.date = dd.date_key
    WHERE year = 2024
    GROUP BY ROLLUP (country, state_name, city)
    ORDER BY state_name, city ASC NULLS LAST;



-- test the tt_analytics schema  
SELECT COUNT(*) AS fact_sales_rows FROM tt_analytics.fact_sales;    
SELECT SUM(sales_amount) AS total_sales_amount FROM tt_analytics.fact_sales;

SELECT state_name, COALESCE(city, 'Total'), SUM(sales_amount) AS total_sales_amount 
    FROM tt_analytics.fact_sales
    JOIN tt_analytics.dim_customer_location AS cl ON fact_sales.customer_id = cl.customer_id
    JOIN tt_analytics.dim_date AS dd ON fact_sales.date = dd.date_key
    WHERE year = 2024
    GROUP BY ROLLUP (state_name, city)
    ORDER BY state_name, city ASC NULLS LAST;



SELECT 'vo_analytics.vw_fact_sales', COUNT(*) FROM vo_analytics.vw_fact_sales
UNION ALL
SELECT 'mv_analytics.mv_fact_sales', COUNT(*) FROM mv_analytics.mv_fact_sales
UNION ALL
SELECT 'tt_analytics.fact_sales', COUNT(*)  FROM tt_analytics.fact_sales;

