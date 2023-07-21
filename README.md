# SQL - Explore Ecommerce Dataset
## I. Introduction
This project contains an eCommerce dataset that I will explore using SQL on [Google BigQuery](https://cloud.google.com/bigquery). The dataset is based on the Google Analytics public dataset and contains data from an eCommerce website.
## II. Requirements
- Google Cloud Platform account
- Project on Google Cloud Platform
- Google BigQuery API enabled
- SQL query editor or IDE
### III. Dataset Access
The eCommerce dataset is stored in a public Google BigQuery dataset. To access the dataset, follow these steps:

- Log in to your Google Cloud Platform account and create a new project.
- Navigate to the BigQuery console and select your newly created project.
- In the navigation panel, select "Add Data" and then "Search a project".
- Enter the project ID "bigquery-public-data.google_analytics_sample.ga_sessions" and click "Enter".
- Click on the "ga_sessions_" table to open it.
### IV. Exploring the Dataset
In this project, I will write 08 query in Bigquery base on Google Analytics dataset
#### Query 01: Calculate total visit, pageview, transaction and revenue for January, February and March 2017 order by month
* SQL code
  ![image](https://i.postimg.cc/Hn3rrb3Y/Screen-Shot-2023-07-21-at-12-34-01.png)
* Query result 
  ![image](https://i.postimg.cc/G3zNLHrq/Screen-Shot-2023-07-21-at-12-34-37.png)
#### Query 02: Bounce rate per traffic source in July 2017
* SQL code
```
SELECT  trafficSource.source AS source,
        COUNT (visitId) AS total_visits,
        COUNT (totals.bounces) AS total_no_of_bounces,
        (COUNT (totals.bounces)/COUNT (visitId	))*100 AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
      WHERE _table_suffix BETWEEN '20170701' AND '20170731'
      GROUP BY source
ORDER BY total_visits DESC
LIMIT 5
```
* Query result 
  ![image](https://i.postimg.cc/bwTrwxCs/Screen-Shot-2023-07-21-at-13-33-03.png)
#### Query 03: Revenue by traffic source by week, by month in June 2017
* SQL code
```
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
```
* Query result
  ![image](https://i.postimg.cc/JnL5wVh9/Screen-Shot-2023-07-21-at-13-45-59.png)
#### Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017
* SQL code
```
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

```
* Query result
  ![image](https://i.postimg.cc/JnL5wVh9/Screen-Shot-2023-07-21-at-13-45-59.png)  
#### Query 05: Average number of transactions per user that made a purchase in July 2017
* SQL code
```
SELECT 
SUBSTRING(date, 1, 6)  AS month,
SUM(totals.transactions)/ COUNT(DISTINCT(fullVisitorId)) AS avg_transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE totals.transactions >=1 AND productRevenue >0
GROUP BY month
```
* Query result
  ![image](https://i.postimg.cc/JnrKDCWj/Screen-Shot-2023-07-21-at-13-50-32.png)
#### Query 06: Average amount of money spent per session
* SQL code
```
SELECT 
SUBSTRING(date, 1, 6)  AS month,
ROUND((SUM(product.productRevenue)/ COUNT(visitID))/1000000,2) AS avg_spendpersession
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
 UNNEST (hits) hits,
 UNNEST (hits.product) product
WHERE totals.transactions IS NOT NULL AND productRevenue IS NOT NULL
GROUP BY month
```
* Query result
  ![image](https://i.postimg.cc/g0zNrLRg/Screen-Shot-2023-07-21-at-14-02-24.png)
#### Query 07 Products purchased by customers who purchased product A (Classic Ecommerce)
* SQL code
```
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
```
* Query result
  ![image](https://i.postimg.cc/4yN9QX8Q/Screen-Shot-2023-07-21-at-13-55-54.png)
#### Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.
* SQL code
```
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
```
* Query result
  ![image](https://i.postimg.cc/q7qBwz0R/Screen-Shot-2023-07-21-at-13-58-39.png)
## V. Conclusion:
* In conclusion, my exploration of the eCommerce dataset using SQL on Google BigQuery based on the Google Analytics dataset has revealed several interesting insights.
* By exploring eCommerce dataset, I have gained valuable information about total visits, pageview, transactions, bounce rate, and revenue per traffic source,.... which could inform future business decisions.
* To deep dive into the insights and key trends, the next step will visualize the data with some software like Power BI,Tableau,...
* Overall, this project has demonstrated the power of using SQL and big data tools like Google BigQuery to gain insights into large datasets.