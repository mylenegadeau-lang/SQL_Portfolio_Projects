
/*******************************************************************************
  Project: E-Commerce Revenue Recovery & Conversion Optimization
  File: 01_exploration.sql
  Dialect: Google BigQuery Standard SQL
  Author: Mylene Gadeau

  Description:
  This script explores the raw GA4 e-commerce data before cleaning and
  analysis. The goal is to understand the date range, event activity,
  number of users, purchase data, and the structure of product information.
  These checks help identify potential data quality issues before building
  the analysis tables.
*******************************************************************************/


-- =============================================================================
-- SECTION 1: UNDERSTANDING THE DATASET
-- =============================================================================

-- 1.1 Dataset Date Range
-- Question: What period does the dataset cover and how many days contain data?
-- This helps define the time period available for the analysis.

SELECT
  MIN(PARSE_DATE('%Y%m%d', event_date)) AS start_date,
  MAX(PARSE_DATE('%Y%m%d', event_date)) AS end_date,
  COUNT(DISTINCT event_date) AS total_active_days
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;


-- =============================================================================
-- SECTION 2: UNDERSTANDING USER AND EVENT ACTIVITY
-- =============================================================================

-- 2.1 Event Volume by Event Type
-- Question: What types of events occur most often and how many users
-- are associated with each event?
-- This gives an overview of how users interact with the e-commerce platform.

SELECT
  event_name,
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY
  event_name
ORDER BY
  total_events DESC;


-- 2.2 Main E-Commerce Funnel Events
-- Question: How many times do users reach each major stage of the
-- purchasing process?
-- These events will later be used to measure conversion and drop-off.

SELECT event_name, COUNT(*) AS event_count 
FROM bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_* 
WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase') 
GROUP BY event_name 
ORDER BY 
  CASE event_name 
    WHEN 'view_item' THEN 1 
    WHEN 'add_to_cart' THEN 2 WHEN 'begin_checkout' THEN 3 
    WHEN 'purchase' THEN 4 
  END;


-- =============================================================================
-- SECTION 3: CHECKING PURCHASE DATA QUALITY
-- =============================================================================

-- 3.1 Purchase and Transaction Data Check
-- Question: Do purchase events contain transaction IDs and revenue information?
-- This check helps identify missing or incomplete purchase records.

SELECT
COUNT(*) AS total_purchase_events,

COUNTIF(
ecommerce.transaction_id IS NOT NULL
) AS purchases_with_transaction_id,

COUNTIF(
ecommerce.transaction_id IS NULL
) AS purchases_without_transaction_id,

COUNTIF(
ecommerce.purchase_revenue IS NOT NULL
) AS purchases_with_revenue,

COUNTIF(
ecommerce.purchase_revenue IS NULL
) AS purchases_without_revenue

FROM
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
event_name = 'purchase';




-- =============================================================================
-- SECTION 4: CHECKING PRODUCT DATA STRUCTURE
-- =============================================================================

-- 4.1 Product Item Records
-- Question: How many product records are available for the main
-- e-commerce events?
-- This helps confirm that the nested items data can be extracted
-- and used during the cleaning stage.

SELECT
  event_name,
  COUNT(*) AS total_item_records
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
WHERE
  event_name IN (
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  )
GROUP BY
  event_name;
```
