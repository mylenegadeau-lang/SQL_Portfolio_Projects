# Data

This folder is reserved for project data and analysis outputs.

The raw e-commerce event data is **not stored in this repository** because it comes from the Google BigQuery public dataset:

`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

The project queries the dataset directly in BigQuery and creates cleaned and modeled tables for analysis.

### Data Source

* **Source:** Google BigQuery Public Dataset
* **Dataset:** GA4 Obfuscated Sample E-commerce
* **Project dataset:** `e-commerce-revenue-recovery.ecommerce_analytics`

### Project Tables

The analysis uses the following tables created in BigQuery:

* `cleaned_events`
* `cleaned_event_items`
* `customers`
* `products`
* `orders`
* `order_items`

No raw source data is included in this repository.
