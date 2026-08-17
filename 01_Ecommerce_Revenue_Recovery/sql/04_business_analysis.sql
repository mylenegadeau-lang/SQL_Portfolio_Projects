

/*******************************************************************************
  Project: E-Commerce Revenue Recovery & Conversion Optimization
  File: 04_business_analysis.sql
  Dialect: Google BigQuery Standard SQL
  Author: [Mylene Gadeau]

  Description:
  This analysis looks at overall e-commerce performance, customer behavior,
  product and country performance, conversion funnel drop-offs, and marketing
  channels. The goal is to identify where revenue is coming from, where
  customers are dropping out of the buying process, and where the business
  may have opportunities to improve conversions and recover lost sales.
*******************************************************************************/


-- =============================================================================
-- SECTION 1: OVERALL BUSINESS PERFORMANCE
-- =============================================================================

-- 1.1 Total Revenue
-- Question: How much revenue did the business generate in total?
SELECT
  ROUND(SUM(revenue), 2) AS total_revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;
-- Finding: $[360837.0]


-- 1.2 Total Orders
-- Question: How many completed orders were placed?
SELECT
  COUNT(DISTINCT order_id) AS total_orders
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;
-- Finding: [4452]


-- 1.3 Total Customers
-- Question: How many unique customers have made purchases?
SELECT
  COUNT(*) AS total_customers
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.customers`;
-- Finding: [270154]


-- 1.4 Average Order Value (AOV)
-- Question: How much does a customer spend on average per order?
-- AOV = Total Revenue / Total Orders
SELECT
  ROUND(AVG(revenue), 2) AS average_order_value
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;
-- Finding: $[69.14]


-- 1.5 Revenue and Orders Over Time
-- Question: How do daily sales and order volumes change over time?
SELECT
  order_date,
  COUNT(DISTINCT order_id) AS orders,
  ROUND(SUM(revenue), 2) AS revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`
GROUP BY
  order_date
ORDER BY
  order_date ASC;


-- =============================================================================
-- SECTION 2: PRODUCT, COUNTRY AND DEVICE PERFORMANCE
-- =============================================================================

-- 2.1 Top 20 Products by Revenue
-- Question: Which products generate the most revenue?
SELECT
  product_id,
  product_name,
  ROUND(SUM(item_revenue), 2) AS revenue,
  SUM(quantity) AS units_sold
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.order_items`
GROUP BY
  product_id,
  product_name
ORDER BY
  revenue DESC
LIMIT 20;


-- 2.2 Top 20 Products by Units Sold
-- Question: Are the products selling the most units also the products
-- generating the most revenue?
SELECT
  product_id,
  product_name,
  SUM(quantity) AS units_sold,
  ROUND(SUM(item_revenue), 2) AS revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.order_items`
GROUP BY
  product_id,
  product_name
ORDER BY
  units_sold DESC
LIMIT 20;


-- 2.3 Revenue and Orders by Country
-- Question: Which countries generate the most sales?
SELECT
  c.country,
  COUNT(DISTINCT o.order_id) AS orders,
  ROUND(SUM(o.revenue), 2) AS revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders` o
LEFT JOIN
  `e-commerce-revenue-recovery.ecommerce_analytics.customers` c
ON
  o.customer_id = c.customer_id
GROUP BY
  c.country
ORDER BY
  revenue DESC;


-- 2.4 Performance by Device
-- Question: How does purchasing behavior differ between mobile,
-- desktop and tablet users?
SELECT
  device_category,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  ROUND(SUM(
    CASE
      WHEN event_name = 'purchase' THEN purchase_revenue
      ELSE 0
    END
  ), 2) AS revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
GROUP BY
  device_category
ORDER BY
  revenue DESC;


-- =============================================================================
-- SECTION 3: CONVERSION FUNNEL AND REVENUE RECOVERY
-- =============================================================================

-- 3.1 Users at Each Stage of the Buying Journey
-- Question: How many users reach each stage of the purchasing process?
SELECT
  COUNT(DISTINCT IF(event_name = 'view_item', user_pseudo_id, NULL)) AS product_viewers,
  COUNT(DISTINCT IF(event_name = 'add_to_cart', user_pseudo_id, NULL)) AS cart_users,
  COUNT(DISTINCT IF(event_name = 'begin_checkout', user_pseudo_id, NULL)) AS checkout_users,
  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasers
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`;


-- 3.2 Conversion Rate Between Funnel Stages
-- Question: At which stage are we losing the most potential customers?
WITH funnel AS (
  SELECT
    COUNT(DISTINCT IF(event_name = 'view_item', user_pseudo_id, NULL)) AS product_viewers,
    COUNT(DISTINCT IF(event_name = 'add_to_cart', user_pseudo_id, NULL)) AS cart_users,
    COUNT(DISTINCT IF(event_name = 'begin_checkout', user_pseudo_id, NULL)) AS checkout_users,
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasers
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
)
SELECT
  product_viewers,
  cart_users,
  checkout_users,
  purchasers,
  ROUND(SAFE_DIVIDE(cart_users, product_viewers) * 100, 2) AS view_to_cart_rate,
  ROUND(SAFE_DIVIDE(checkout_users, cart_users) * 100, 2) AS cart_to_checkout_rate,
  ROUND(SAFE_DIVIDE(purchasers, checkout_users) * 100, 2) AS checkout_to_purchase_rate
FROM
  funnel;


-- 3.3 Users Who Added to Cart but Did Not Purchase
-- Question: How many users showed buying interest by adding an item to their
-- cart but never completed a purchase?
WITH cart_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE event_name = 'add_to_cart'
),
purchasers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE event_name = 'purchase'
)
SELECT
  COUNT(*) AS cart_users_without_purchase
FROM
  cart_users c
LEFT JOIN
  purchasers p
ON
  c.user_pseudo_id = p.user_pseudo_id
WHERE
  p.user_pseudo_id IS NULL;


-- 3.4 Users Who Started Checkout but Did Not Purchase
-- Question: How many users reached checkout but left before completing payment?
WITH checkout_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE event_name = 'begin_checkout'
),
purchasers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE event_name = 'purchase'
)
SELECT
  COUNT(*) AS checkout_users_without_purchase
FROM
  checkout_users c
LEFT JOIN
  purchasers p
ON
  c.user_pseudo_id = p.user_pseudo_id
WHERE
  p.user_pseudo_id IS NULL;


-- =============================================================================
-- SECTION 4: CUSTOMER BEHAVIOR AND SEGMENTATION
-- =============================================================================

-- 4.1 Repeat Customers
-- Question: Which customers have purchased more than once?
SELECT
  customer_id,
  COUNT(DISTINCT order_id) AS number_of_orders,
  ROUND(SUM(revenue), 2) AS total_revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`
GROUP BY
  customer_id
HAVING
  COUNT(DISTINCT order_id) > 1
ORDER BY
  number_of_orders DESC;


-- 4.2 Top 50 Customers by Lifetime Revenue
-- Question: Which customers have generated the most revenue over time?
SELECT
  customer_id,
  COUNT(DISTINCT order_id) AS orders,
  ROUND(SUM(revenue), 2) AS lifetime_revenue,
  ROUND(AVG(revenue), 2) AS average_order_value
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`
GROUP BY
  customer_id
ORDER BY
  lifetime_revenue DESC
LIMIT 50;


-- 4.3 Customer Value Segments
-- Question: How are customers distributed based on the amount they have spent?
WITH customer_value AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS orders,
    SUM(revenue) AS lifetime_revenue
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.orders`
  GROUP BY
    customer_id
)
SELECT
  customer_id,
  orders,
  ROUND(lifetime_revenue, 2) AS lifetime_revenue,
  CASE
    WHEN lifetime_revenue >= 500 THEN 'High Value'
    WHEN lifetime_revenue >= 200 THEN 'Medium Value'
    ELSE 'Low Value'
  END AS customer_segment
FROM
  customer_value
ORDER BY
  lifetime_revenue DESC;


-- =============================================================================
-- SECTION 5: MARKETING AND TRAFFIC CHANNEL PERFORMANCE
-- =============================================================================

-- 5.1 Revenue and Conversions by Traffic Source
-- Question: Which marketing channels bring in the most users, orders,
-- and revenue?
SELECT
  traffic_source,
  traffic_medium,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT transaction_id) AS transactions,
  ROUND(
    SUM(
      CASE
        WHEN event_name = 'purchase' THEN purchase_revenue
        ELSE 0
      END
    ), 2
  ) AS revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
GROUP BY
  traffic_source,
  traffic_medium
ORDER BY
  revenue DESC;
```
