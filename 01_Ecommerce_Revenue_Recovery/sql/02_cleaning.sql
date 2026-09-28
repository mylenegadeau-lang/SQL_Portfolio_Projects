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

  The cleaning process creates two main tables:
  1. cleaned_events      → event-level information
  2. cleaned_event_items → product-level information
*******************************************************************************/


-- =============================================================================
-- SECTION 1: CLEAN EVENT DATA
-- =============================================================================

-- 1.1 Create the cleaned event-level table.
--
-- Business Question:
-- What event-level information do we need for the analysis?
--
-- The raw GA4 data contains nested device, geography, and ecommerce fields.
-- This step extracts the required information into separate columns so that
-- the event data is easier to analyze.
--
-- Important:
-- This step mainly selects and structures the required fields.
-- It does not perform extensive transformations such as deduplication.


CREATE OR REPLACE TABLE
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events` AS

SELECT

  -- Convert GA4 date from YYYYMMDD text into a proper DATE
  PARSE_DATE('%Y%m%d', event_date) AS event_date,

  -- Event information
  event_timestamp,
  event_name,

  -- User information
  user_pseudo_id,
  user_id,

  -- Platform information
  platform,

  -- Device information
  device.category AS device_category,
  device.operating_system AS operating_system,
  device.web_info.browser AS browser,

  -- Geographic information
  geo.country AS country,
  geo.city AS city,

  -- Ecommerce transaction information
  ecommerce.transaction_id AS transaction_id,
  ecommerce.purchase_revenue AS purchase_revenue,

  -- Event-level ecommerce summary fields
  ecommerce.total_item_quantity AS total_item_quantity,
  ecommerce.unique_items AS unique_items

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

-- Keep records that can be associated with a user
WHERE
  user_pseudo_id IS NOT NULL;


-- =============================================================================
-- SECTION 2: CLEAN PRODUCT ITEM DATA
-- =============================================================================

-- 2.1 Create the product-level event table.
--
-- Business Question:
-- How can we extract individual products from the nested GA4 items array?
--
-- GA4 stores product information inside a nested "items" array.
-- UNNEST() converts each product item into its own row.
--
-- This creates a separate product-level table that can be used for:
-- - product views
-- - add-to-cart analysis
-- - checkout analysis
-- - purchase analysis
-- - product revenue analysis


CREATE OR REPLACE TABLE
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_event_items` AS

SELECT

  -- Event information
  PARSE_DATE('%Y%m%d', event_date) AS event_date,
  event_timestamp,
  event_name,

  -- User information
  user_pseudo_id,

  -- Product information
  items.item_id AS item_id,
  items.item_name AS item_name,
  items.quantity AS quantity,
  items.price AS price

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS items

WHERE
  user_pseudo_id IS NOT NULL

  -- Keep only the main ecommerce events used in the project
  AND event_name IN (
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  )

  -- Remove product records without a usable product name
  AND items.item_name IS NOT NULL
  AND items.item_name != '(not set)';


-- =============================================================================
-- SECTION 3: DATA QUALITY CHECKS
-- =============================================================================


-- 3.1 Check for missing user IDs
--
-- Question:
-- Did any records with a NULL user ID make it into the cleaned event table?
--
-- Expected result: 0


SELECT
  COUNT(*) AS null_user_count
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_events`
WHERE
  user_pseudo_id IS NULL;


-- =============================================================================
-- 3.2 Check for missing product names
-- =============================================================================

-- Question:
-- Did any product records without a valid product name make it
-- into the cleaned product-level table?
--
-- Expected result: 0


SELECT
  COUNT(*) AS invalid_product_name_count
FROM
  `e-commerce-revenue-recovery.ecommerce_analytics.cleaned_event_items`
WHERE
  item_name IS NULL
  OR item_name = '(not set)';


-- =============================================================================
-- 3.3 Check for repeated purchase transaction IDs
-- =============================================================================

-- Question:
-- Are any purchase transaction IDs appearing more than once?
--
-- This helps identify possible duplicate purchase records.
--
-- An empty result means that no repeated transaction IDs were found.


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

