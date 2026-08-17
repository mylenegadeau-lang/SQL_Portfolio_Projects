
/*******************************************************************************
  Project: E-Commerce Revenue Recovery & Conversion Optimization
  File: 02_cleaning.sql
  Dialect: Google BigQuery Standard SQL
  Author: Mylene Gadeau

  Description:
  This script cleans and prepares the raw GA4 event data for analysis.
  It extracts the fields needed for the project, converts nested data
  into a simpler structure, handles missing values, and creates staging
  tables that will be used for the data model and business analysis.
*******************************************************************************/


-- =============================================================================
-- SECTION 1: CLEAN EVENT DATA
-- =============================================================================

-- Create a cleaned event-level table.
-- The raw GA4 data contains nested fields, so this step extracts the
-- information needed for the analysis into separate columns.

CREATE OR REPLACE TABLE `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events` AS

SELECT
  -- Convert the GA4 date from YYYYMMDD text into a proper DATE
  PARSE_DATE('%Y%m%d', event_date) AS event_date,

  event_timestamp,
  event_name,
  user_pseudo_id,

  -- Extract device and country information
  device.category AS device_category,
  geo.country AS country,

  -- Extract the traffic source and medium
  traffic_source.name AS traffic_source,
  traffic_source.medium AS traffic_medium,

  -- Extract the transaction ID from the nested event parameters
  (
    SELECT value.string_value
    FROM UNNEST(event_params)
    WHERE key = 'transaction_id'
  ) AS transaction_id,

  -- Extract purchase value and handle different numeric data types
  (
    SELECT COALESCE(
      value.double_value,
      CAST(value.int_value AS FLOAT64)
    )
    FROM UNNEST(event_params)
    WHERE key = 'value'
  ) AS purchase_revenue

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

-- Only keep records that can be linked to a user
WHERE
  user_pseudo_id IS NOT NULL;


-- =============================================================================
-- SECTION 2: CLEAN PRODUCT DATA
-- =============================================================================

-- Create a product-level staging table.
-- GA4 stores purchased and viewed products inside a nested items array.
-- UNNEST is used to turn those nested items into individual rows.

CREATE OR REPLACE TABLE `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_product_events` AS

SELECT
  PARSE_DATE('%Y%m%d', e.event_date) AS event_date,
  e.event_timestamp,
  e.event_name,
  e.user_pseudo_id,

  -- Extract the transaction ID from the event parameters
  (
    SELECT value.string_value
    FROM UNNEST(e.event_params)
    WHERE key = 'transaction_id'
  ) AS transaction_id,

  -- Product information from the nested items array
  item.item_id AS product_id,
  item.item_name AS product_name,
  item.price AS item_price,

  -- If quantity is missing, assume one unit
  COALESCE(item.quantity, 1) AS quantity,

  -- Use the recorded item revenue when available.
  -- Otherwise, calculate it using price × quantity.
  COALESCE(
    item.item_revenue,
    item.price * COALESCE(item.quantity, 1)
  ) AS item_revenue

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e,

  -- Flatten the nested product items
  UNNEST(e.items) AS item

WHERE
  e.user_pseudo_id IS NOT NULL

  -- Keep only records with a usable product ID
  AND item.item_id IS NOT NULL
  AND item.item_id != '(not set)';


-- =============================================================================
-- SECTION 3: DATA QUALITY CHECKS
-- =============================================================================

-- 3.1 Check for missing user IDs
-- Question: Did any records with a NULL user ID make it into the cleaned table?
-- The expected result should be 0.

SELECT
  COUNT(*) AS null_user_count
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
WHERE
  user_pseudo_id IS NULL;


-- 3.2 Check for repeated purchase transaction IDs
-- Question: Are any purchase transaction IDs appearing more than once?
-- This helps identify possible duplicate purchase records.

SELECT
  transaction_id,
  COUNT(*) AS occurrence_count
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
WHERE
  event_name = 'purchase'
  AND transaction_id IS NOT NULL
GROUP BY
  transaction_id
HAVING
  COUNT(*) > 1;
```
