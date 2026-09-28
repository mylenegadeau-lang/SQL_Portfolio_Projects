/*******************************************************************************
  Project: E-Commerce Revenue Recovery & Conversion Optimization
  File: 04_business_analysis.sql
  Dialect: Google BigQuery Standard SQL
  Author: Mylene Gadeau

  Description:
  This analysis evaluates overall business performance, product performance,
  geographic and device performance, customer behavior, conversion funnel
  drop-offs, and marketing channels.

  The goal is to identify:
    1. Where revenue is being generated
    2. Which products and markets contribute most to revenue
    3. How customers behave and purchase over time
    4. Where customers drop out of the conversion funnel
    5. Where potential revenue recovery opportunities may exist

  Analysis approach:
    Business Question → SQL Query → Result → Business Interpretation
*******************************************************************************/


-- =============================================================================
-- SECTION 1: OVERALL BUSINESS PERFORMANCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 Total Revenue
-- -----------------------------------------------------------------------------
-- Business Question:
-- How much revenue did the business generate in total?

SELECT
  ROUND(SUM(revenue), 2) AS total_revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;

-- Finding:
-- Total revenue = $311,376.00

-- Business Interpretation:
-- The analyzed orders generated $311,376 in total revenue.
-- This provides the overall revenue baseline for the project and is used
-- to compare revenue performance across products, countries, customers,
-- and other dimensions.



-- -----------------------------------------------------------------------------
-- 1.2 Total Orders
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many completed orders were placed?

SELECT
  COUNT(DISTINCT order_id) AS total_orders
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;

-- Finding:
-- Total orders = 4,509

-- Business Interpretation:
-- The business recorded 4,509 distinct orders.
-- This metric provides the basis for calculating average order value
-- and understanding overall purchasing activity.



-- -----------------------------------------------------------------------------
-- 1.3 Total Customer Records
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many customer records are stored in the customer table?

SELECT
  COUNT(*) AS total_customer_records
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.customers`;

-- Finding:
-- Total customer records = 270,154

-- Business Interpretation:
-- The customer table contains 270,154 customer records.
-- However, this number is much larger than the number of customers who
-- actually placed an order, so it should not be interpreted as the number
-- of active purchasing customers.



-- -----------------------------------------------------------------------------
-- 1.4 Unique Purchasing Customers
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many unique customers actually placed an order?

SELECT
  COUNT(DISTINCT customer_id) AS unique_purchasing_customers
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;

-- Finding:
-- Unique purchasing customers = 3,713

-- Business Interpretation:
-- 3,713 unique customers generated the recorded orders.
-- Comparing this number with the 270,154 customer records shows that the
-- customer table contains many records that did not generate an order
-- during the analyzed period.



-- -----------------------------------------------------------------------------
-- 1.5 Average Order Value (AOV)
-- -----------------------------------------------------------------------------
-- Business Question:
-- How much revenue does an order generate on average?
--
-- AOV = Total Revenue / Total Orders

SELECT
  ROUND(AVG(revenue), 2) AS average_order_value
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;

-- Finding:
-- Average Order Value = $69.06

-- Business Interpretation:
-- An order generated an average of $69.06 in revenue.
-- This provides a baseline for evaluating order value across products
-- and customer segments.



-- -----------------------------------------------------------------------------
-- 1.6 Revenue per Purchasing Customer
-- -----------------------------------------------------------------------------
-- Business Question:
-- How much revenue does each purchasing customer generate on average?
--
-- Revenue per Purchasing Customer =
-- Total Revenue / Unique Purchasing Customers

SELECT
  ROUND(
    SUM(revenue) / COUNT(DISTINCT customer_id),
    2
  ) AS revenue_per_purchasing_customer
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;

-- Finding:
-- Revenue per purchasing customer = $83.86

-- Business Interpretation:
-- Each purchasing customer generated an average of $83.86 in revenue
-- during the analyzed period.
--
-- This metric is different from AOV because one customer may place
-- multiple orders.



-- -----------------------------------------------------------------------------
-- 1.7 Repeat Purchase Rate
-- -----------------------------------------------------------------------------
-- Business Question:
-- What percentage of purchasing customers placed more than one order?

WITH customer_orders AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS order_count
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.orders`
  GROUP BY
    customer_id
)

SELECT
  ROUND(
    COUNTIF(order_count > 1) / COUNT(*) * 100,
    2
  ) AS repeat_purchase_rate
FROM
  customer_orders;

-- Finding:
-- Repeat purchase rate = 12.60%

-- Business Interpretation:
-- 12.60% of purchasing customers placed more than one order.
-- This means the majority of purchasing customers placed only one order
-- during the analyzed period, while a smaller group returned to purchase
-- again.



-- -----------------------------------------------------------------------------
-- 1.8 Revenue and Orders Over Time
-- -----------------------------------------------------------------------------
-- Business Question:
-- How do daily sales and order volumes change over time?

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

-- Finding:
-- Daily revenue and order volume vary across the analyzed period.
-- The available order data begins on 2020-11-11.

-- Business Interpretation:
-- Daily performance is not constant.
-- Examining revenue and order volume over time can help identify
-- periods of higher or lower purchasing activity and can provide
-- a basis for future seasonal or campaign analysis.



-- =============================================================================
-- SECTION 2: PRODUCT, COUNTRY AND DEVICE PERFORMANCE
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 2.1 Top 20 Products by Revenue
-- -----------------------------------------------------------------------------
-- Business Question:
-- Which products generate the most revenue?

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

-- Key Findings:
-- 1. Google Canteen Bottle Black:
--      $4,905 revenue, 250 units
-- 2. Google Utility BackPack:
--      $4,848 revenue, 49 units
-- 3. Google Zip Hoodie F/C:
--      $4,080 revenue, 81 units
-- 4. Google Campus Bike:
--      $3,840 revenue, 116 units
-- 5. Google Incognito Techpack V2:
--      $3,630 revenue, 48 units

-- Business Interpretation:
-- The Google Canteen Bottle Black generated the highest recorded
-- revenue among the product IDs analyzed.
--
-- The Google Utility BackPack generated almost the same total revenue
-- with only 49 units sold, showing that high revenue can come from
-- either high sales volume or higher revenue per unit.
--
-- Product IDs are kept separate in this analysis because identical
-- product names may correspond to different product IDs/SKUs.



-- -----------------------------------------------------------------------------
-- 2.2 Top 20 Products by Units Sold
-- -----------------------------------------------------------------------------
-- Business Question:
-- Which products sell the highest number of units?

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

-- Key Findings:
-- 1. Google Laptop and Cell Phone Stickers:
--      380 units, $975 revenue
-- 2. Google Clear Pen 4-Pack:
--      368 units, $1,201 revenue
-- 3. Google Metallic Notebook Set:
--      334 units, $1,740 revenue
-- 4. Google Pen White:
--      300 units, $395 revenue
-- 5. Google Camp Mug Ivory:
--      260 units, $2,729 revenue

-- Business Interpretation:
-- The products with the highest unit sales are not necessarily
-- the products generating the highest revenue.
--
-- For example, Google Laptop and Cell Phone Stickers sold 380 units
-- but generated $975, while Google Canteen Bottle Black sold 250 units
-- and generated $4,905.
--
-- This demonstrates why both sales volume and revenue should be
-- considered when evaluating product performance.



-- -----------------------------------------------------------------------------
-- 2.3 Product Revenue vs Units Sold
-- -----------------------------------------------------------------------------
-- Business Question:
-- How does revenue per unit differ across high-revenue products?

SELECT
  product_id,
  product_name,
  SUM(quantity) AS units_sold,
  ROUND(SUM(item_revenue), 2) AS revenue,
  ROUND(
    SUM(item_revenue) / NULLIF(SUM(quantity), 0),
    2
  ) AS revenue_per_unit
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.order_items`
GROUP BY
  product_id,
  product_name
ORDER BY
  revenue DESC
LIMIT 20;

-- Key Findings:
-- Google Utility BackPack:
--      49 units, $4,848 revenue, $98.94 per unit
--
-- Google Canteen Bottle Black:
--      250 units, $4,905 revenue, $19.62 per unit
--
-- Google Camp Mug Ivory:
--      260 units, $2,729 revenue, $10.50 per unit

-- Business Interpretation:
-- Revenue performance is influenced by both product volume and
-- revenue per unit.
--
-- The Google Utility BackPack sold 201 fewer units than the
-- Google Canteen Bottle Black but generated $57 less revenue
-- overall despite having a much higher revenue per unit.
--
-- The Canteen Bottle combines relatively high unit volume with
-- meaningful revenue per unit, making it an important contributor
-- to recorded product revenue.



-- -----------------------------------------------------------------------------
-- 2.4 Revenue and Orders by Country
-- -----------------------------------------------------------------------------
-- Business Question:
-- Which countries generate the most sales?

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

-- Key Findings:
-- United States:
--      1,964 orders, $137,446 revenue
--
-- India:
--      408 orders, $29,440 revenue
--
-- Canada:
--      367 orders, $27,525 revenue
--
-- United Kingdom:
--      139 orders, $10,058 revenue
--
-- Spain:
--      106 orders, $6,864 revenue
--
-- France:
--      97 orders, $5,893 revenue
--
-- Country = "(not set)":
--      28 orders, $1,283 revenue

-- Business Interpretation:
-- The United States generated the highest recorded revenue and
-- order volume in the dataset.
--
-- India and Canada were the next largest contributors by revenue.
--
-- The presence of "(not set)" country values shows that some geographic
-- information is missing. These records were retained rather than
-- silently excluded so that the analysis does not hide data-quality issues.



-- -----------------------------------------------------------------------------
-- 2.5 Performance by Device
-- -----------------------------------------------------------------------------
-- Business Question:
-- How does purchasing activity differ between desktop, mobile and tablet?

SELECT
  device_category,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  ROUND(
    SUM(
      CASE
        WHEN event_name = 'purchase' THEN purchase_revenue
        ELSE 0
      END
    ),
    2
  ) AS revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
GROUP BY
  device_category
ORDER BY
  revenue DESC;

-- Key Findings:
-- Desktop:
--      158,917 users
--      3,226 purchase events
--      $208,815 revenue
--
-- Mobile:
--      109,195 users
--      2,355 purchase events
--      $146,768 revenue
--
-- Tablet:
--      6,250 users
--      111 purchase events
--      $6,582 revenue

-- Business Interpretation:
-- Desktop generated the highest recorded revenue and purchase-event
-- volume, followed by mobile.
--
-- Tablet activity was substantially smaller.
--
-- This analysis shows differences in purchasing activity by device,
-- but it does not establish that one device converts better than another.
-- A device-specific conversion rate would require an additional analysis.



-- =============================================================================
-- SECTION 3: CONVERSION FUNNEL AND REVENUE RECOVERY
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 3.1 Users at Each Stage of the Buying Journey
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many unique users reach each stage of the purchasing process?

SELECT
  COUNT(DISTINCT IF(event_name = 'view_item', user_pseudo_id, NULL))
    AS product_viewers,

  COUNT(DISTINCT IF(event_name = 'add_to_cart', user_pseudo_id, NULL))
    AS cart_users,

  COUNT(DISTINCT IF(event_name = 'begin_checkout', user_pseudo_id, NULL))
    AS checkout_users,

  COUNT(DISTINCT IF(event_name = 'add_shipping_info', user_pseudo_id, NULL))
    AS shipping_users,

  COUNT(DISTINCT IF(event_name = 'add_payment_info', user_pseudo_id, NULL))
    AS payment_users,

  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL))
    AS purchasers
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`;

-- Key Findings:
-- Product viewers = 61,252
-- Cart users = 12,545
-- Checkout users = 9,715
-- Shipping users = 9,714
-- Payment users = 5,751
-- Purchasers = 4,419

-- Overall conversion:
-- 4,419 purchasers / 61,252 product viewers = 7.21%
--
-- Note:
-- The project also contains transaction/order-level metrics.
-- The 4,419 figure represents unique purchasing users, while
-- 4,509 represents distinct completed orders in the orders table.



-- -----------------------------------------------------------------------------
-- 3.2 Conversion Rate Between Funnel Stages
-- -----------------------------------------------------------------------------
-- Business Question:
-- At which stages are the largest numbers of users lost?

WITH funnel AS (
  SELECT
    COUNT(DISTINCT IF(event_name = 'view_item', user_pseudo_id, NULL))
      AS product_viewers,

    COUNT(DISTINCT IF(event_name = 'add_to_cart', user_pseudo_id, NULL))
      AS cart_users,

    COUNT(DISTINCT IF(event_name = 'begin_checkout', user_pseudo_id, NULL))
      AS checkout_users,

    COUNT(DISTINCT IF(event_name = 'add_shipping_info', user_pseudo_id, NULL))
      AS shipping_users,

    COUNT(DISTINCT IF(event_name = 'add_payment_info', user_pseudo_id, NULL))
      AS payment_users,

    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL))
      AS purchasers
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
)

SELECT
  product_viewers,
  cart_users,
  checkout_users,
  shipping_users,
  payment_users,
  purchasers,

  ROUND(
    SAFE_DIVIDE(cart_users, product_viewers) * 100,
    2
  ) AS view_to_cart_rate,

  ROUND(
    SAFE_DIVIDE(checkout_users, cart_users) * 100,
    2
  ) AS cart_to_checkout_rate,

  ROUND(
    SAFE_DIVIDE(shipping_users, checkout_users) * 100,
    2
  ) AS checkout_to_shipping_rate,

  ROUND(
    SAFE_DIVIDE(payment_users, shipping_users) * 100,
    2
  ) AS shipping_to_payment_rate,

  ROUND(
    SAFE_DIVIDE(purchasers, payment_users) * 100,
    2
  ) AS payment_to_purchase_rate,

  ROUND(
    SAFE_DIVIDE(purchasers, checkout_users) * 100,
    2
  ) AS checkout_to_purchase_rate
FROM
  funnel;

-- Key Findings:
-- View → Cart:
--      20.48% conversion
--      79.52% drop-off
--      48,707 users lost
--
-- Cart → Checkout:
--      77.44% conversion
--      2,830 users lost
--
-- Checkout → Shipping:
--      99.99% conversion
--      1 user lost
--
-- Shipping → Payment:
--      59.20% conversion
--      3,963 users lost
--
-- Payment → Purchase:
--      76.84% conversion
--      1,332 users lost
--
-- Checkout → Purchase:
--      45.49% conversion
--
-- Overall Product View → Purchase:
--      7.21%

-- Business Interpretation:
-- The largest numerical drop occurs between product viewing and
-- adding an item to the cart.
--
-- A second major drop occurs between shipping information and
-- payment information.
--
-- The checkout-to-shipping stage shows almost no user loss in
-- this dataset.
--
-- These results identify the stages where further investigation
-- could potentially help recover lost conversions. However, the
-- funnel data alone does not explain WHY users leave each stage.



-- -----------------------------------------------------------------------------
-- 3.3 Users Who Added to Cart but Did Not Purchase
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many users showed buying interest by adding an item to their cart
-- but never completed a purchase?

WITH cart_users AS (
  SELECT DISTINCT
    user_pseudo_id
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE
    event_name = 'add_to_cart'
),

purchasers AS (
  SELECT DISTINCT
    user_pseudo_id
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE
    event_name = 'purchase'
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

-- Finding:
-- 9,630 users added a product to their cart but did not complete
-- a recorded purchase.
--
-- This represents approximately 76.77% of the 12,545 unique cart users.

-- Business Interpretation:
-- 9,630 users demonstrated purchase intent by adding a product
-- to their cart but did not complete a recorded purchase.
--
-- These users represent a potential audience for further analysis
-- of cart abandonment and checkout behavior.
--
-- The dataset does not explain why these users did not purchase,
-- so the result should be interpreted as an observed behavior
-- rather than a confirmed reason for abandonment.



-- -----------------------------------------------------------------------------
-- 3.4 Users Who Started Checkout but Did Not Purchase
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many users reached checkout but did not complete a purchase?

WITH checkout_users AS (
  SELECT DISTINCT
    user_pseudo_id
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE
    event_name = 'begin_checkout'
),

purchasers AS (
  SELECT DISTINCT
    user_pseudo_id
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
  WHERE
    event_name = 'purchase'
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

-- Finding:
-- 5,296 users started checkout but did not complete a recorded purchase.
--
-- This represents approximately 54.49% of the 9,715 unique checkout users.

-- Business Interpretation:
-- 5,296 users reached the checkout stage but did not complete
-- a recorded purchase.
--
-- These users demonstrated stronger purchase intent than users
-- who only viewed or added products to their cart.
--
-- This group represents a potential area for further investigation
-- into checkout and payment behavior.
--
-- The dataset does not identify the specific reasons why these users
-- did not complete a purchase, so the result should be interpreted
-- as an observed behavior rather than a confirmed cause.



-- =============================================================================
-- SECTION 4: CUSTOMER BEHAVIOR AND RETENTION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 4.1 Customer Purchase Frequency
-- -----------------------------------------------------------------------------
-- Business Question:
-- How many orders does each purchasing customer place?

WITH customer_orders AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS order_count
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.orders`
  GROUP BY
    customer_id
)

SELECT
  order_count,
  COUNT(*) AS customers
FROM
  customer_orders
GROUP BY
  order_count
ORDER BY
  order_count ASC;

-- Key Findings:
-- 1 order  = 3,245 customers
-- 2 orders = 320 customers
-- 3 orders = 84 customers
-- 4 orders = 25 customers
-- 5 orders = 11 customers
-- 6 orders = 12 customers
-- 7 orders = 6 customers
-- 8 orders = 3 customers
-- 9 orders = 2 customers
-- 10 orders = 1 customer
-- 11 orders = 2 customers
-- 13 orders = 1 customer
-- 16 orders = 1 customer
--
-- Total repeat customers = 468
-- Total purchasing customers = 3,713
-- Repeat purchase rate = 12.60%

-- Business Interpretation:
-- Most purchasing customers placed only one order.
--
-- A smaller group of 468 customers placed more than one order.
--
-- One customer placed 16 orders during the analyzed period.
--
-- The data shows different purchasing frequencies, but it does not
-- explain why customers purchase once or return repeatedly.



-- -----------------------------------------------------------------------------
-- 4.2 One-Time vs Repeat Customer Revenue
-- -----------------------------------------------------------------------------
-- Business Question:
-- How much revenue comes from one-time customers versus repeat customers?

WITH customer_orders AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(revenue) AS customer_revenue
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.orders`
  GROUP BY
    customer_id
)

SELECT
  CASE
    WHEN order_count = 1 THEN 'One-time customer'
    ELSE 'Repeat customer'
  END AS customer_type,

  COUNT(*) AS customers,

  ROUND(SUM(customer_revenue), 2) AS revenue
FROM
  customer_orders
GROUP BY
  customer_type
ORDER BY
  revenue DESC;

-- Key Findings:
-- One-time customers:
--      3,245 customers
--      $230,609 revenue
--
-- Repeat customers:
--      468 customers
--      $80,767 revenue
--
-- Average revenue per one-time customer:
--      approximately $71.06
--
-- Average revenue per repeat customer:
--      approximately $172.58

-- Business Interpretation:
-- One-time customers are much more numerous and therefore contribute
-- more total revenue in the analyzed period.
--
-- However, the average revenue generated per repeat customer is
-- substantially higher than the average revenue generated per
-- one-time customer.
--
-- This suggests that repeat purchasing behavior is associated with
-- higher total customer value in this dataset.
--
-- This is an association, not proof that repeat purchasing itself
-- causes higher customer value.



-- -----------------------------------------------------------------------------
-- 4.3 Average Orders and Revenue per Purchasing Customer
-- -----------------------------------------------------------------------------
-- Business Question:
-- On average, how many orders does a purchasing customer make,
-- and how much revenue does each purchasing customer generate?

SELECT
  COUNT(DISTINCT order_id) / COUNT(DISTINCT customer_id)
    AS average_orders_per_customer,

  ROUND(
    SUM(revenue) / COUNT(DISTINCT customer_id),
    2
  ) AS average_revenue_per_customer
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`;

-- Key Findings:
-- Average orders per purchasing customer = 1.214381901427417
-- Rounded = 1.21 orders
--
-- Average revenue per purchasing customer = $83.86

-- Business Interpretation:
-- Purchasing customers placed an average of approximately 1.21 orders.
--
-- The average is above one because some customers made repeat purchases.
--
-- The $83.86 result confirms the Revenue per Purchasing Customer
-- calculation from Section 1.6.



-- -----------------------------------------------------------------------------
-- 4.4 Customer Revenue Distribution
-- -----------------------------------------------------------------------------
-- Business Question:
-- Which customers generated the highest total revenue?

SELECT
  customer_id,
  COUNT(DISTINCT order_id) AS order_count,
  ROUND(SUM(revenue), 2) AS customer_revenue
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders`
GROUP BY
  customer_id
ORDER BY
  customer_revenue DESC
LIMIT 20;

-- Key Findings:
-- Highest customer revenue observed:
--      $1,530 from 1 order
--
-- Other examples:
--      $1,424 from 3 orders
--      $1,404 from 11 orders
--      $1,260 from 5 orders
--      $1,200 from 1 order

-- Business Interpretation:
-- High customer revenue can result from different purchasing patterns.
--
-- Some high-revenue customers generated substantial revenue from
-- a single order, while others generated revenue through repeated
-- purchases.
--
-- Therefore, customer revenue and purchase frequency should be
-- analyzed together rather than treated as the same metric.



-- -----------------------------------------------------------------------------
-- 4.5 Average Order Value: One-Time vs Repeat Customers
-- -----------------------------------------------------------------------------
-- Business Question:
-- Do repeat customers place larger orders on average than one-time customers?

WITH customer_orders AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS order_count
  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.orders`
  GROUP BY
    customer_id
)

SELECT
  CASE
    WHEN co.order_count = 1 THEN 'One-time customer'
    ELSE 'Repeat customer'
  END AS customer_type,

  COUNT(DISTINCT o.order_id) AS orders,

  ROUND(SUM(o.revenue), 2) AS revenue,

  ROUND(
    SUM(o.revenue) / COUNT(DISTINCT o.order_id),
    2
  ) AS average_order_value
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.orders` o
JOIN
  customer_orders co
ON
  o.customer_id = co.customer_id
GROUP BY
  customer_type
ORDER BY
  average_order_value DESC;

-- Key Findings:
-- One-time customers:
--      3,245 orders
--      $230,609 revenue
--      $71.07 average order value
--
-- Repeat customers:
--      1,264 orders
--      $80,767 revenue
--      $63.90 average order value

-- Business Interpretation:
-- One-time customers had a higher average order value than repeat
-- customers: $71.07 compared with $63.90.
--
-- Therefore, repeat customers do not generate higher customer value
-- because their individual orders are larger.
--
-- Their higher average customer revenue is associated with making
-- multiple purchases over time.
--
-- This demonstrates the difference between:
--      Order Value = value of an individual order
--      Customer Value = total revenue generated by a customer



-- =============================================================================
-- SECTION 5: MARKETING AND TRAFFIC CHANNEL PERFORMANCE
-- =============================================================================


-- -----------------------------------------------------------------------------
-- -- 5.1 Revenue and Purchasing Activity by Traffic Source
-- -----------------------------------------------------------------------------
-- Business Question:
-- Which traffic sources are associated with the most purchasing users,
-- transactions, and revenue?
--
-- Note:
-- traffic_source is not included in the cleaned_events table.
-- Therefore, this analysis uses the raw GA4 event tables directly.

SELECT
  traffic_source.source AS traffic_source,
  traffic_source.medium AS traffic_medium,
  traffic_source.name AS campaign_name,

  COUNT(DISTINCT user_pseudo_id) AS purchasing_users,

  COUNT(DISTINCT ecommerce.transaction_id) AS transactions,

  ROUND(
    SUM(ecommerce.purchase_revenue),
    2
  ) AS revenue

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
  event_name = 'purchase'

GROUP BY
  traffic_source,
  traffic_medium,
  campaign_name

ORDER BY
  revenue DESC;


-- Finding:
-- Google organic traffic generated the highest recorded revenue:
-- $95,775 from 1,229 purchasing users and 1,156 transactions.
--
-- Direct traffic generated $79,650 from 1,054 purchasing users
-- and 970 transactions.
--
-- Other referral and anonymized traffic sources also contributed
-- meaningful revenue.
--
-- Google CPC generated $9,056 from 152 purchasing users
-- and 133 transactions.
--
-- Some traffic-source values are anonymized or grouped as
-- '(data deleted)' and '<Other>', so their underlying sources
-- cannot be identified from the dataset.


-- Business Interpretation:
-- Google organic was the largest identified traffic source by
-- recorded revenue during the analyzed period.
--
-- Direct traffic was the second-largest identified source by
-- recorded revenue.
--
-- These results describe the revenue associated with each
-- recorded traffic source. They do not prove that one channel
-- is more efficient than another because marketing costs,
-- acquisition costs, and return on advertising spend are not
-- available in this dataset.
--
-- The anonymized '(data deleted)' and '<Other>' categories should
-- be treated as data limitations rather than interpreted as
-- specific marketing channels.
--
-- A future analysis could compare traffic-source revenue with
-- marketing spend to evaluate channel efficiency.


-- =============================================================================
-- SECTION 6: OVERALL BUSINESS INSIGHTS
-- =============================================================================

/*
  KEY BUSINESS FINDINGS
  ---------------------

  1. Overall Performance
     - Total recorded revenue: $311,376
     - Total completed orders: 4,509
     - Unique purchasing customers: 3,713
     - Average order value: $69.06
     - Average revenue per purchasing customer: $83.86

     Business Insight:
     The dataset recorded $311,376 in revenue across 4,509 completed orders.
     The difference between completed orders and unique purchasing customers
     reflects the presence of repeat customers.


  2. Customer Retention
     - 3,245 customers placed only one order.
     - 468 customers placed more than one order.
     - Repeat purchase rate: 12.60%.
     - Repeat customers generated $80,767 in revenue.
     - One-time customers generated $230,609 in revenue.
     - Average revenue per repeat customer: approximately $172.58.
     - Average revenue per one-time customer: approximately $71.06.

     Business Insight:
     Most purchasing customers placed only one order during the analyzed
     period. Repeat customers were fewer in number but generated higher
     average customer revenue because they placed multiple orders.


  3. Customer Order Value
     - One-time customer AOV: $71.07
     - Repeat customer AOV: $63.90
     - Repeat customers did not have larger individual orders on average.
     - Their higher average customer revenue was associated with placing
       multiple orders.

     Business Insight:
     Order value and customer value should be analyzed separately.
     A customer can generate higher total revenue through multiple
     purchases even when individual orders are smaller on average.


  4. Product Performance
     - Google Canteen Bottle Black generated the highest recorded
       product revenue: $4,905.
     - Google Utility BackPack generated $4,848 from 49 units.
     - High unit sales do not necessarily result in the highest revenue.
     - Product performance should therefore consider both units sold
       and revenue generated.

     Business Insight:
     Revenue performance varies across products, so product analysis
     should consider both sales volume and revenue rather than relying
     on a single metric.


  5. Product Conversion Patterns
     - The Google Tracking Hat had 1,414 unique product viewers and
       no recorded add-to-cart users.
     - Among products with at least 1,000 viewers, the Google Tracking
       Hat had a 0.00% recorded view-to-cart rate.
     - Product price showed a weak negative correlation with
       view-to-cart rate (r = -0.222).
     - Device-level view-to-cart rates were relatively close:
       tablet 19.13%, desktop 20.33%, and mobile 20.73%.
     

     Business Insight:
     Product-level behavior showed meaningful differences in
     view-to-cart performance. However, these patterns are associations
     and do not establish the causes of lower conversion.


  6. Geographic Performance
     - The United States generated the highest recorded revenue:
       $137,446 from 1,964 orders.
     - India and Canada were the next largest contributors by revenue.
     - Some customer records contain missing country information.

     Business Insight:
     Revenue was concentrated in several geographic markets, with
     the United States contributing the largest recorded amount.


  7. Device Performance
     - Desktop generated $208,815 from 3,226 purchase events.
     - Mobile generated $146,768 from 2,355 purchase events.
     - Tablet generated $6,582 from 111 purchase events.
     - These figures describe purchasing activity by device and do not
       establish device-specific conversion rates.

     Business Insight:
     Desktop accounted for the largest recorded purchasing activity
     in this dataset. Device-level revenue should be interpreted
     alongside user counts and conversion rates.


  8. Traffic Source Performance
     - Google organic generated the highest recorded revenue:
       $95,775 from 1,229 purchasing users and 1,156 transactions.
     - Direct traffic generated $79,650 from 1,054 purchasing users
       and 970 transactions.
     - Google CPC generated $9,056 from 152 purchasing users and
       133 transactions.
     - Some traffic-source values are anonymized or grouped as
       "(data deleted)" and "<Other>".

     Business Insight:
     Google organic and direct traffic were the largest identified
     sources by recorded revenue. However, revenue alone does not
     establish channel efficiency because marketing and acquisition
     costs are not available in the dataset.


  9. Conversion Funnel
     - 61,252 users viewed products.
     - 12,545 users added products to their cart.
     - 9,715 users started checkout.
     - 9,714 users provided shipping information.
     - 5,751 users provided payment information.
     - 4,419 users completed a purchase.
     - View-to-cart conversion: 20.48%.
     - View-to-cart drop-off: 79.52%.
     - Shipping-to-payment conversion: 59.20%.
     - Payment-to-purchase conversion: 76.84%.
     - The largest numerical user loss occurred between product viewing
       and adding an item to the cart.

     Business Insight:
     The product-view-to-cart stage represents the largest numerical
     drop-off in the purchasing journey, followed by the shipping-to-
     payment stage.


  10. Revenue Recovery Opportunities
      - 9,630 cart users had no recorded purchase.
      - 5,296 checkout users had no recorded purchase.
      - The product-view-to-cart stage lost 48,707 users.
      - The shipping-to-payment stage lost approximately 3,963 users.

      Business Insight:
      The funnel contains substantial groups of users who demonstrated
      purchase intent but did not complete a recorded purchase.
      These groups provide opportunities for further investigation
      into conversion and revenue recovery.


  11. Data Quality Considerations
      - Country values include "(not set)" records.
      - Product names can appear under multiple product IDs.
      - Some traffic-source values are anonymized or grouped.
      - The traffic-source fields are available in the raw GA4 data
        but were not included in the cleaned_events table.
      - Unique purchasing users and completed orders are different
        metrics and should not be treated as interchangeable.
      - Some users may appear at different funnel stages without a
        perfectly sequential event path in the dataset.


  12. Overall Project Conclusion
      - The analysis identified the largest funnel drop-offs,
        customer retention patterns, product-level conversion
        differences, geographic and device purchasing patterns,
        and traffic sources associated with recorded revenue.
      - The largest numerical funnel loss occurred between product
        viewing and adding to cart.
      - A second significant loss occurred between shipping information
        and payment information.
      - Product price, device, and brand showed different patterns
        across products or segments, but the available data does not
        establish causation.
      - Further investigation would be required before making specific
        operational recommendations.


-- =============================================================================
-- END OF BUSINESS ANALYSIS
-- =============================================================================