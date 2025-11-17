/*
----------------------------------------------------------
Project : Retail Profit Lab
Phase   : 2 - Exploration & KPI
Author  : Cecilia Torres
Date    : 2025-11-05
Purpose : Business exploration with essential SQL patterns.
----------------------------------------------------------
*/

USE superstore_db;

#1.create clean view 
#a.Distinct customers (dimension-like)
CREATE OR REPLACE VIEW v_customers AS
SELECT DISTINCT
  customer_id, customer_name, segment, region, state, city
FROM v_orders;

#b.Distinct products (dimension-like)
CREATE OR REPLACE VIEW v_products AS
SELECT DISTINCT
  product_id, product_name, category, sub_category
FROM v_orders;

#c.a continue month table (even if we have no sales in a month)
#with a recursive Common Table Expression  

CREATE OR REPLACE VIEW v_months AS
WITH RECURSIVE months AS (
  SELECT DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS month FROM v_orders
  UNION ALL
  SELECT DATE_FORMAT(DATE_ADD(month, INTERVAL 1 MONTH), '%Y-%m-01')
  FROM months
  WHERE DATE_ADD(month, INTERVAL 1 MONTH) <= (SELECT DATE_FORMAT(MAX(order_date), '%Y-%m-01') FROM v_orders)
)
SELECT month FROM months;


#2. global KPI (WHERE, aggregates)

SELECT
  ROUND(SUM(sales),2)  AS total_sales,
  ROUND(SUM(profit),2) AS total_profit,
  ROUND(AVG(margin_rate), 4) AS avg_margin_rate_unweighted,
  ROUND(SUM(profit) / SUM(sales), 4) AS avg_margin_rate_weighted
FROM v_orders
WHERE order_date IS NOT NULL;
#Global KPI Summary:
#Total Sales: 26,456.86 | Total Profit: 58.85 
#Unweighted Avg Margin: 13.35% | Weighted Avg Margin: 0.22%
#→ Despite a decent per-order margin, the overall business profitability is very low (~0.2% of total sales).
#→ Suggests that numerous low- or negative-margin transactions are offsetting a few profitable ones.

#3 top/flop products (ORDER BY, LIMIT)

#a. top 10 by profit
SELECT product_id, product_name, ROUND(SUM(profit),2) AS profit
FROM v_orders
GROUP BY 1,2
ORDER BY profit DESC
LIMIT 10;
#Top 10 most profitable products:
#Phones, conference tables, and binding machines dominate the profit ranking.
# → Suggests that technology and office equipment drive most of the positive margin.
# → Indicates stable demand for productivity-related items and communication devices.

#b. flop 10 (loss-makers)
SELECT product_id, product_name, ROUND(SUM(profit),2) AS profit
FROM v_orders
GROUP BY 1,2
HAVING SUM(profit) < 0
ORDER BY profit ASC
LIMIT 10;
#Bottom 10 least profitable products:
#Large furniture items (bookcases, tables, lamps) show the biggest losses.
#→ High logistics and storage costs likely erode profitability.
#→ Indicates potential overstocking or inefficient pricing in the furniture category.


#4. segments (GROUP BY, HAVING)
SELECT segment,
       ROUND(SUM(sales),2)  AS sales,
       ROUND(SUM(profit),2) AS profit,
       ROUND(AVG(margin_rate),4) AS avg_margin
FROM v_orders
GROUP BY segment
HAVING SUM(sales) > 0
ORDER BY profit DESC;
#segment performance summary:
#Corporate clients are the only profitable segment (+638.68), 
#while both Consumer (-548.87) and Home Office (-30.97) are unprofitable.
#→ Despite the highest sales volume, the Consumer segment faces major margin erosion (21% avg margin but negative total profit).
#→ Suggests pricing or discounting issues in the Consumer market.

#5. discounts vs margin (bins + weighted margin)
WITH base AS (
  SELECT
    CASE
      WHEN discount = 0            THEN '0%'
      WHEN discount < 0.10         THEN '0-10%'
      WHEN discount < 0.20         THEN '10-20%'
      WHEN discount < 0.30         THEN '20-30%'
      ELSE '>=30%'
    END AS discount_bucket,
    sales, profit, margin_rate
  FROM v_orders
)
SELECT
  discount_bucket,
  ROUND(SUM(sales), 2)                               AS sales,
  ROUND(SUM(profit), 2)                              AS profit,
  ROUND(AVG(margin_rate), 4)                         AS avg_margin_unweighted,
  ROUND(SUM(profit) / NULLIF(SUM(sales),0), 4)       AS avg_margin_weighted,
  COUNT(*)                                           AS n_rows
FROM base
GROUP BY discount_bucket
ORDER BY CASE discount_bucket
  WHEN '0%'    THEN 0
  WHEN '0-10%' THEN 1
  WHEN '10-20%' THEN 2
  WHEN '20-30%' THEN 3
  ELSE 4 END;

#discount impact summary:
#0% discount yields the highest profit and margin (24%).
#Moderate discounts (20–30%) remain viable with reduced margin (~9%).
#Deep discounts (≥30%) cause significant losses (-44% weighted margin).
#→ Recommendation: cap discounts below 30% and monitor the 20–30% range closely.


#6.shipping impact (WHERE, GROUP BY)
SELECT ship_mode,
       ROUND(AVG(shipping_delay_days),2) AS avg_delay_days,
       ROUND(AVG(margin_rate),4)         AS avg_margin
FROM v_orders
WHERE shipping_delay_days IS NOT NULL
GROUP BY ship_mode
ORDER BY avg_margin DESC;
#shipping impact summary:
#faster shipping correlates with higher margins.
#standard class has the longest delays (~5 days) and lowest margin (~9%).
#second class offers best trade-off: moderate speed (3.5 days) + highest margin (~21%).
# → Recommendation: promote “Second Class” delivery as the optimal value option.


#7. time-series with calendar LEFT JOIN (show months with 0)
SELECT
  m.month,
  COALESCE(SUM(v.sales),0)  AS sales,
  COALESCE(SUM(v.profit),0) AS profit
FROM v_months m
LEFT JOIN v_monthly v
  ON v.month = m.month
GROUP BY m.month
ORDER BY m.month;
#time series with calendar join:
#the LEFT JOIN to v_months forces a dense monthly series, showing months with zero activity.
#Notable months: strong peaks (e.g., 2016-12), losses (e.g., 2015-09), and several zero months (no orders recorded).

#8.count how many cities are overall profitable (Positive) vs unprofitable (Negative)
WITH city_profit AS (
  SELECT DISTINCT city, 'Positive' AS status
  FROM v_orders
  GROUP BY city
  HAVING SUM(profit) > 0

  UNION

  SELECT DISTINCT city, 'Negative' AS status
  FROM v_orders
  GROUP BY city
  HAVING SUM(profit) < 0
)
SELECT
  status,
  COUNT(*) AS city_count,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM city_profit
GROUP BY status;

#Insight:
#out of 44 cities, 34 (77%) are overall profitable while 10 (23%) generate losses.
#the business shows a healthy geographic footprint, but targeted actions may be needed
#to improve performance in underperforming locations.

#8.2a. identify loss-making cities and quantify their losses (with state context).
WITH negative_cities AS (
  SELECT
    city,
    state,
    SUM(profit)  AS total_profit,
    SUM(sales)   AS total_sales,
    COUNT(*)     AS order_count
  FROM v_orders
  GROUP BY city, state
  HAVING SUM(profit) < 0
)
SELECT
  city,
  state,
  total_profit,
  total_sales,
  order_count
FROM negative_cities
ORDER BY total_profit ASC;  -- most negative first

#10 cities across 7 states show negative profitability, concentrated mainly in Pennsylvania,
#Illinois, Tennessee, and Texas. Philadelphia stands out as the largest loss center (-1.63K profit)
#despite high sales volume, suggesting structural or pricing inefficiencies rather than low demand.


#8.2b. for loss-making cities, show which product categories drive the losses.
WITH negative_cities AS (
  SELECT city, state
  FROM v_orders
  GROUP BY city, state
  HAVING SUM(profit) < 0
),
city_category AS (
  SELECT
    o.city,
    o.state,
    o.category,
    SUM(o.sales)  AS sales,
    SUM(o.profit) AS profit
  FROM v_orders o
  JOIN negative_cities nc
    ON nc.city = o.city AND nc.state = o.state
  GROUP BY o.city, o.state, o.category
)
SELECT
  city,
  state,
  category,
  profit,
  sales,
  ROUND(
    100 * -profit
    / NULLIF(SUM(-LEAST(profit,0)) OVER (PARTITION BY city, state), 0)
  , 2) AS pct_of_city_loss
FROM city_category
WHERE profit < 0                   #focus on categories that actually lose money
ORDER BY city, state, profit ASC;  #worst categories per city first

#most city-level losses stem from the Furniture category (present in 7 of 10 unprofitable cities),
# followed by Office Supplies in Tennessee and Texas. Technology losses are minor except in Aurora.
#Overall, Furniture accounts for the majority of deficits in key markets, indicating margin pressure
#or excessive discounting in that segment.
