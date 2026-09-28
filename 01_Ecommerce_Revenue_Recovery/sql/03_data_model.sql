/*******************************************************************************
  Project: E-Commerce Revenue Recovery & Conversion Optimization
  File: 03_data_model.sql
  Dialect: Google BigQuery Standard SQL
  Author: Mylene Gadeau

  Description:
  This script organizes the cleaned e-commerce data into separate tables
  that are easier to analyze.

  It creates:
  1. customers     → one record per customer
  2. products      → one record per product
  3. orders        → one record per order
  4. order_items   → one record per product within an order

  These tables create a structured analytical model for the
  business analysis stage.
*******************************************************************************/


-- =============================================================================
-- SECTION 1: CUSTOMER TABLE
-- =============================================================================

-- Business Question:
-- Who are the customers in the dataset and when were they first and
-- last observed?

-- Create one record per customer.

CREATE OR REPLACE TABLE
  `e-commerce-revenue-recovery.ecommerce_analytics.customers` AS

SELECT
  user_pseudo_id AS customer_id,

  -- First date the customer appeared in the dataset
  MIN(event_date) AS first_seen_date,

  -- Most recent date the customer appeared in the dataset
  MAX(event_date) AS last_seen_date,

  -- Customer's country
  MAX(country) AS country,

  -- Device category associated with the customer
  MAX(device_category) AS primary_device

FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`

WHERE
  user_pseudo_id IS NOT NULL

GROUP BY
  customer_id;


-- =============================================================================
-- SECTION 2: PRODUCT TABLE
-- =============================================================================

-- Business Question:
-- What products are available in the e-commerce dataset and what is
-- their observed unit price?

-- Create one record for each product.

CREATE OR REPLACE TABLE
  `e-commerce-revenue-recovery.ecommerce_analytics.products` AS

SELECT
  item_id AS product_id,
  item_name AS product_name,

  ROUND(MAX(price), 2) AS estimated_unit_price

FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_event_items`

WHERE
  item_id IS NOT NULL
  AND item_id != '(not set)'
  AND item_name IS NOT NULL
  AND item_name != '(not set)'

GROUP BY
  product_id,
  product_name;


-- =============================================================================
-- SECTION 3: ORDERS TABLE
-- =============================================================================

CREATE OR REPLACE TABLE
  `e-commerce-revenue-recovery.ecommerce_analytics.orders` AS

WITH purchase_events AS (

  SELECT
    event_date,
    event_timestamp,
    transaction_id,
    user_pseudo_id,
    purchase_revenue,
    total_item_quantity,
    unique_items,

    LAG(event_timestamp) OVER (
      PARTITION BY
        transaction_id,
        user_pseudo_id,
        total_item_quantity,
        unique_items
      ORDER BY
        event_timestamp
    ) AS previous_timestamp

  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`

  WHERE
    event_name = 'purchase'
    AND transaction_id IS NOT NULL
    AND transaction_id != '(not set)'
),

classified_purchases AS (

  SELECT
    *,
    CASE
      WHEN previous_timestamp IS NOT NULL
       AND TIMESTAMP_DIFF(
         event_timestamp,
         previous_timestamp,
         MILLISECOND
       ) <= 10000
      THEN 1
      ELSE 0
    END AS is_duplicate

  FROM
    purchase_events
),

valid_purchases AS (

  SELECT
    *
  FROM
    classified_purchases
  WHERE
    is_duplicate = 0
)

SELECT
  CONCAT(
    transaction_id,
    '_',
    user_pseudo_id,
    '_',
    CAST(UNIX_MICROS(event_timestamp) AS STRING)
  ) AS order_id,

  transaction_id,

  user_pseudo_id AS customer_id,

  event_date AS order_date,

  ROUND(purchase_revenue, 2) AS revenue

FROM
  valid_purchases;

-- =============================================================================
-- SECTION 4: ORDER ITEMS TABLE
-- =============================================================================

-- Business Question:
-- Which products were included in each valid order, and how much revenue
-- did each product generate?
--
-- Duplicate purchase events are removed using the same 10-second rule
-- used by the orders table.

CREATE OR REPLACE TABLE
  `e-commerce-revenue-recovery.ecommerce_analytics.order_items` AS

WITH purchase_events AS (

  SELECT
    event_date,
    event_timestamp,
    transaction_id,
    user_pseudo_id,
    purchase_revenue,
    total_item_quantity,
    unique_items,

    LAG(event_timestamp) OVER (
      PARTITION BY
        transaction_id,
        user_pseudo_id,
        total_item_quantity,
        unique_items
      ORDER BY
        event_timestamp
    ) AS previous_timestamp

  FROM
    `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`

  WHERE
    event_name = 'purchase'
    AND transaction_id IS NOT NULL
    AND transaction_id != '(not set)'
),

classified_purchases AS (

  SELECT
    *,
    CASE
      WHEN previous_timestamp IS NOT NULL
       AND TIMESTAMP_DIFF(
         event_timestamp,
         previous_timestamp,
         MILLISECOND
       ) <= 10000
      THEN 1
      ELSE 0
    END AS is_duplicate

  FROM
    purchase_events
),

valid_purchase_events AS (

  SELECT
    event_date,
    event_timestamp,
    transaction_id,
    user_pseudo_id

  FROM
    classified_purchases

  WHERE
    is_duplicate = 0
)

SELECT
  CONCAT(
    v.transaction_id,
    '_',
    v.user_pseudo_id,
    '_',
    CAST(UNIX_MICROS(v.event_timestamp) AS STRING)
  ) AS order_id,

  i.item_id AS product_id,

  i.item_name AS product_name,

  SUM(i.quantity) AS quantity,

  ROUND(
    SUM(i.price * i.quantity),
    2
  ) AS item_revenue

FROM
  valid_purchase_events AS v

JOIN
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_event_items` AS i

ON
  v.transaction_id = i.transaction_id
  AND v.user_pseudo_id = i.user_pseudo_id
  AND v.event_timestamp = TIMESTAMP_MICROS(i.event_timestamp)

WHERE
  i.event_name = 'purchase'
  AND i.item_id IS NOT NULL
  AND i.item_id != '(not set)'
  AND i.item_name IS NOT NULL
  AND i.item_name != '(not set)'

GROUP BY
  order_id,
  product_id,
  product_name;