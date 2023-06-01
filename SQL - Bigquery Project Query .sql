-- Big project for SQL
-- Link instruction: https://docs.google.com/spreadsheets/d/1WnBJsZXj_4FDi2DyfLH1jkWtfTridO2icWbWCh7PLs8/edit#gid=0


-- Query 01: calculate total visit, pageview, transaction and revenue for Jan, Feb and March 2017 order by month
#standardSQL
SELECT 
 SUBSTRING(date, 1, 6)  AS month,
 COUNT(visitID) AS visit, 
 SUM(totals.pageviews) AS pageviews, 
 SUM(totals.transactions) AS transactions, 
 SUM(totals.totalTransactionRevenue/10000) AS revenue,      
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _table_suffix BETWEEN '20170101' AND '20170331' 
GROUP BY month 
ORDER BY month

-- Query 02: Bounce rate per traffic source in July 2017
#standardSQL
SELECT  trafficSource.source AS source,
        COUNT (visitId) AS total_visits,
        COUNT (totals.bounces) AS total_no_of_bounces,
        (COUNT (totals.bounces)/COUNT (visitId	))*100 AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
      WHERE _table_suffix BETWEEN '20170701' AND '20170731'
      GROUP BY source
ORDER BY total_visits DESC
LIMIT 5

-- Query 3: Revenue by traffic source by week, by month in June 2017

WITH new_table AS 
(SELECT PARSE_DATE ("%Y%m%d", date) As time, trafficSource.source,product.productRevenue
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product 
 WHERE product.productRevenue IS NOT NULL)

(
SELECT "Week" AS time_type,
        EXTRACT(WEEK FROM time) AS week, 
        source, 
        SUM(productRevenue) AS revenue
FROM new_table
GROUP BY week, source
ORDER BY revenue DESC
LIMIT 2
)

UNION ALL

(
SELECT  "Month" AS time_type,
        EXTRACT(MONTH FROM time) AS month, 
        source,
        SUM(productRevenue) AS revenue
FROM new_table
GROUP BY month,source
ORDER BY revenue DESC
LIMIT 2
)

--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
#standardSQL
WITH 
a AS 
(SELECT 
SUBSTRING(date, 1, 6)  AS month,
SUM(totals.pageviews)/ COUNT(DISTINCT(fullVisitorId)) AS avg_pageviews_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE totals.transactions >=1 AND productRevenue IS NOT NULL
GROUP BY month),

b AS
(SELECT 
SUBSTRING(date, 1, 6)  AS month,
SUM(totals.pageviews)/ COUNT(DISTINCT(fullVisitorId)) AS avg_pageviews_non_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE totals.transactions IS NULL AND productRevenue IS NULL
GROUP BY month)

SELECT a.month,avg_pageviews_purchase,avg_pageviews_non_purchase 
FROM a JOIN b ON a.month =  b.month
WHERE a.month IN ('201706','201707')
ORDER BY month 



-- Query 05: Average number of transactions per user that made a purchase in July 2017
#standardSQL
SELECT 
SUBSTRING(date, 1, 6)  AS month,
SUM(totals.transactions)/ COUNT(DISTINCT(fullVisitorId)) AS avg_transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE totals.transactions >=1 AND productRevenue >0
GROUP BY month

-- Query 06: Average amount of money spent per session
#standardSQL
SELECT 
SUBSTRING(date, 1, 6)  AS month,
SUM(product.productRevenue)/ COUNT(visitID) AS avg_spendpersession
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE totals.transactions IS NOT NULL AND productRevenue IS NOT NULL
GROUP BY month


-- Query 07: Products purchased by customers who purchased product A (Classic Ecommerce)
#standardSQL
WITH a AS
(SELECT DISTINCT(fullVisitorId) AS ID, product.v2ProductName
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
WHERE product.v2ProductName LIKE "YouTube Men's Vintage Henley"
AND product.productRevenue IS NOT NULL)

SELECT product.v2ProductName AS other_purchased_products, 
       SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
WHERE fullVisitorId IN (SELECT ID FROM a)
GROUP BY product.v2ProductName
ORDER BY quantity DESC 

--Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.
#standardSQL

SELECT a.month, a.num_product_view, b.num_addtocard, c.num_purchase,
       (b.num_addtocard*100/a.num_product_view) AS addtocard_rate,
       (c.num_purchase*100/a.num_product_view) AS purchase_rate
FROM (
(SELECT  SUBSTRING(date, 1, 6)  AS month,
        COUNT(hits.eCommerceAction.action_type) AS num_product_view
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits
WHERE hits.eCommerceAction.action_type = '2'
GROUP BY month) a
JOIN
(SELECT  SUBSTRING(date, 1, 6)  AS month,
        COUNT(hits.eCommerceAction.action_type) AS num_addtocard
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits
WHERE hits.eCommerceAction.action_type = '3'
GROUP BY month) b
ON a.month = b.month
JOIN
(SELECT  SUBSTRING(date, 1, 6)  AS month,
        COUNT(hits.eCommerceAction.action_type) AS num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits
WHERE hits.eCommerceAction.action_type = '6'
GROUP BY month) c
ON a.month =  c.month) 

WHERE a.month IN ('201701','201702','201703')

