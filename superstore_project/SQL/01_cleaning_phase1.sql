/*
----------------------------------------------------------
Project : Retail Profit Lab
Phase   : 1 - Structuring & Cleaning
Author  : Cecilia Torres
Date    : 2025-11-05
Purpose : Transform raw Superstore data into clean, analysis-ready views.
----------------------------------------------------------
*/

#1. Create clean view v_orders
#converts text dates, computes shipping delay & margin rate
USE superstore_db;

CREATE OR REPLACE VIEW v_orders AS
SELECT
  `Row ID` AS row_id,
  `Order ID` AS order_id,
  STR_TO_DATE(`Order Date`, '%m/%d/%Y') AS order_date,
  STR_TO_DATE(`Ship Date`,  '%m/%d/%Y') AS ship_date,
  DATEDIFF(
    STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),
    STR_TO_DATE(`Order Date`, '%m/%d/%Y')
  ) AS shipping_delay_days,
  `Ship Mode` AS ship_mode,
  `Customer ID` AS customer_id,
  `Customer Name` AS customer_name,
  `Segment` AS segment,
  `Country` AS country,
  `City` AS city,
  `State` AS state,
  `Region` AS region,
  `Product ID` AS product_id,
  `Category` AS category,
  `Sub-Category` AS sub_category,
  `Product Name` AS product_name,
  sales,
  quantity,
  discount,
  profit,
  CASE WHEN sales <> 0 THEN profit / sales ELSE NULL END AS margin_rate
FROM superstore;


#2. Create montly aggregated view v_monthly
#summarises sales, profit & margin per month/segment/region/category
CREATE OR REPLACE VIEW v_monthly AS
SELECT
  DATE_FORMAT(order_date, '%Y-%m-01') AS month,
  segment,
  region,
  category,
  SUM(sales) AS sales,
  SUM(profit) AS profit,
  AVG(margin_rate) AS avg_margin_rate,
  COUNT(*) AS n_orders
FROM v_orders
GROUP BY 1,2,3,4;

#3. check duplicates
SELECT
COUNT(*) AS total_rows,
COUNT(DISTINCT row_id) AS distinct_row_id
FROM v_orders; 
#both counts equal (138),  no duplicated row_id

SELECT order_id, product_id, COUNT(*) AS cnt
FROM v_orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 20;
# no results = no duplicates found 

#4. check NULL values in key columns
SELECT
  SUM(order_id IS NULL)     AS null_order_id,
  SUM(order_date IS NULL)   AS null_order_date,
  SUM(ship_date IS NULL)    AS null_ship_date,
  SUM(customer_id IS NULL)  AS null_customer_id,
  SUM(product_id IS NULL)   AS null_product_id,
  SUM(category IS NULL)     AS null_category,
  SUM(sales IS NULL)        AS null_sales,
  SUM(profit IS NULL)       AS null_profit
FROM v_orders;
#all NULL counts = 0; dataset complete and consistent

#5.validate temporal range and basic stats
#a) date range
SELECT 
  MIN(order_date) AS min_order_date,
  MAX(order_date) AS max_order_date
FROM v_orders;
#orders span from 2014.05.13 to 2017.12.25

#b) total number of rows
SELECT COUNT(*) AS n_rows FROM v_orders;
#138 rows in total 

#c) yearly distribution of orders 
SELECT 
  YEAR(order_date) AS year, 
  COUNT(*) AS n_orders
FROM v_orders
GROUP BY 1
ORDER BY 1;
#2014 = 24; 2015 = 36; 2016 = 54; 2017 =24

#d) average and range of shipping delays 
SELECT
  AVG(shipping_delay_days) AS avg_delay,
  MIN(shipping_delay_days) AS min_delay,
  MAX(shipping_delay_days) AS max_delay
FROM v_orders;
#average delay ~ 4 days 4.21 | min = 1 | max = 7

### END ###
 