# E-Commerce Revenue Recovery & Conversion Optimization

## 📊 Project Overview

This project analyzes e-commerce customer behavior and purchasing activity using **Google BigQuery and SQL**.

The analysis focuses on the customer journey from **product viewing to purchase** to identify where users drop out of the funnel and where potential revenue recovery opportunities may exist.

The project also examines product performance, customer purchasing behavior, geographic markets, device usage, and traffic sources.

---

## 🎯 Business Problem

An e-commerce business can generate significant traffic without converting all visitors into customers.

The key business questions explored in this project are:

* Where are customers dropping out of the purchasing funnel?
* Which products generate the most revenue?
* Which products have high sales volume but lower revenue?
* How do one-time and repeat customers behave?
* Which countries contribute the most revenue?
* How does purchasing activity differ across devices?
* Which traffic sources are associated with recorded revenue?
* Where might potential revenue recovery opportunities exist?

---

## 🔍 Project Objectives

The analysis aims to:

1. Explore and understand raw GA4 e-commerce event data.
2. Clean and prepare the data for analysis.
3. Build analytical tables for customers, products, orders, and order items.
4. Analyze overall business and revenue performance.
5. Measure conversion rates across the purchasing funnel.
6. Identify major funnel drop-offs.
7. Analyze product and customer purchasing behavior.
8. Examine geographic, device, and traffic-source patterns.
9. Identify areas for further revenue recovery investigation.
10. Document data-quality limitations and analytical assumptions.

---

## 🛠️ Tools & Technologies

* **Google BigQuery**
* **SQL**
* **Google BigQuery Standard SQL**
* **GitHub**
* **Markdown**

### SQL Techniques Used

* `SELECT`
* `WHERE`
* `GROUP BY`
* `ORDER BY`
* `CASE`
* `COUNT`
* `COUNTIF`
* `COUNT DISTINCT`
* `SUM`
* `AVG`
* `ROUND`
* `SAFE_DIVIDE`
* `NULLIF`
* `JOIN`
* `LEFT JOIN`
* `UNNEST`
* Common Table Expressions (`CTEs`)
* Window functions such as `LAG`
* `TIMESTAMP_DIFF`
* Correlation analysis using `CORR`

---

## 📂 Data Source

The project uses the public **Google Analytics 4 (GA4) Obfuscated Sample E-commerce Dataset** available through Google BigQuery.

Source table:

```text
bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
```

The raw dataset is queried directly in BigQuery and is **not stored in this GitHub repository**.

The analysis covers event data from approximately:

**November 1, 2020 to January 31, 2021**

---

## 🔄 Project Workflow

```text
Raw GA4 E-commerce Data
          ↓
     Exploration
          ↓
       Cleaning
          ↓
    Data Modeling
          ↓
 Business Analysis
          ↓
 Funnel Analysis
          ↓
 Revenue Recovery Insights
```

### SQL Files

| File                       | Purpose                                                                                     |
| -------------------------- | ------------------------------------------------------------------------------------------- |
| `01_exploration.sql`       | Explores the raw dataset and identifies important event, user, product, and funnel patterns |
| `02_cleaning.sql`          | Cleans and prepares event and item-level data                                               |
| `03_data_model.sql`        | Creates analytical tables for customers, products, orders, and order items                  |
| `04_business_analysis.sql` | Performs business analysis and identifies funnel drop-offs and revenue patterns             |

---

## 🗂️ Data Model

The project creates four main analytical entities:

```text
Customers
    │
    ▼
 Orders
    │
    ▼
Order Items
    │
    ▼
 Products
```

### Customers

Contains customer-level information such as:

* Customer ID
* First seen date
* Last seen date
* Observed country
* Observed device

### Products

Contains:

* Product ID
* Product name
* Estimated unit price

### Orders

Contains:

* Order ID
* Transaction ID
* Customer ID
* Order date
* Revenue

### Order Items

Contains:

* Order ID
* Product ID
* Product name
* Quantity
* Item revenue

---

# 📈 Key Findings

## Overall Business Performance

The modeled dataset contains:

* **$311,376** in recorded revenue
* **4,509** analytical orders
* **3,713** unique purchasing customers
* **$69.06** average order value
* **$83.86** average revenue per purchasing customer
* **12.60%** repeat purchase rate

---

## 🛒 Conversion Funnel

The analysis identified the following unique users at each stage:

| Funnel Stage         |  Users |
| -------------------- | -----: |
| Product View         | 61,252 |
| Add to Cart          | 12,545 |
| Begin Checkout       |  9,715 |
| Shipping Information |  9,714 |
| Payment Information  |  5,751 |
| Purchase             |  4,419 |

### Largest Funnel Drop-Off

The largest numerical drop occurred between **product viewing and add-to-cart**:

* Viewers: **61,252**
* Cart users: **12,545**
* View-to-cart conversion: **20.48%**
* Users not progressing to cart: **48,707**
* Drop-off: **79.52%**

A second significant drop occurred between shipping information and payment information:

* Shipping users: **9,714**
* Payment users: **5,751**
* Users lost: approximately **3,963**
* Conversion: **59.20%**

The dataset identifies these drop-off points but does not establish the reasons why users left each stage.

---

## 🛍️ Product Performance

The highest recorded product revenue included:

| Product                      | Revenue | Units Sold |
| ---------------------------- | ------: | ---------: |
| Google Canteen Bottle Black  |  $4,905 |        250 |
| Google Utility BackPack      |  $4,848 |         49 |
| Google Zip Hoodie F/C        |  $4,080 |         81 |
| Google Campus Bike           |  $3,840 |        116 |
| Google Incognito Techpack V2 |  $3,630 |         48 |

The analysis also showed that high unit sales do not necessarily correspond to the highest revenue.

For example, **Google Laptop and Cell Phone Stickers** sold 380 units but generated $975, while **Google Canteen Bottle Black** sold 250 units and generated $4,905.

---

## 🔎 Product Conversion Patterns

One notable product-level pattern was the **Google Tracking Hat**:

* **1,414** unique product viewers
* **2,893** recorded view events
* **0** recorded add-to-cart users
* **0.00%** recorded view-to-cart rate

Among products with at least 1,000 viewers, this was an unusually low observed result.

Product price also showed a **weak negative correlation** with view-to-cart rate:

**r = -0.222**

This indicates an observed relationship between price and product-level conversion, but price alone does not explain the differences in product performance.

---

## 👥 Customer Behavior

The analysis found:

* **3,245** one-time customers
* **468** repeat customers
* **12.60%** repeat purchase rate

Average revenue per customer:

| Customer Type | Customers |  Revenue | Avg. Revenue per Customer |
| ------------- | --------: | -------: | ------------------------: |
| One-time      |     3,245 | $230,609 |                   ~$71.06 |
| Repeat        |       468 |  $80,767 |                  ~$172.58 |

However, repeat customers did **not** have larger individual orders on average:

* One-time customer AOV: **$71.07**
* Repeat customer AOV: **$63.90**

Their higher total customer revenue was associated with placing multiple orders rather than larger individual orders.

---

## 🌍 Geographic Performance

The United States generated the highest recorded revenue:

* **1,964 orders**
* **$137,446 revenue**

Other major contributors included:

* India: **$29,440**
* Canada: **$27,525**
* United Kingdom: **$10,058**
* Spain: **$6,864**
* France: **$5,893**

Some records contain missing country values.

---

## 💻 Device Performance

Purchasing activity by device was:

| Device  | Purchase Events |  Revenue |
| ------- | --------------: | -------: |
| Desktop |           3,226 | $208,815 |
| Mobile  |           2,355 | $146,768 |
| Tablet  |             111 |   $6,582 |

These figures describe purchasing activity and revenue by device. They should not be interpreted as device conversion rates because the number of product viewers by device must also be considered.

A separate funnel analysis found relatively similar view-to-cart rates:

* Tablet: **19.13%**
* Desktop: **20.33%**
* Mobile: **20.73%**

---

## 📣 Traffic Source Performance

Traffic-source information was analyzed directly from the raw GA4 dataset because these fields were not included in the cleaned event table.

Largest identified sources by recorded revenue included:

| Traffic Source   | Revenue | Purchasing Users |
| ---------------- | ------: | ---------------: |
| Google / Organic | $95,775 |            1,229 |
| Direct           | $79,650 |            1,054 |
| Google / CPC     |  $9,056 |              152 |

Some traffic-source values are anonymized or grouped as `(data deleted)` and `<Other>`.

Revenue alone cannot establish channel efficiency because marketing and acquisition costs are not available in the dataset.

---

# 💡 Revenue Recovery Opportunities

The funnel analysis identified several groups for further investigation:

### Product View → Add to Cart

**48,707 users** did not progress from product viewing to a recorded add-to-cart event.

### Cart → Purchase

**9,630 users** added a product to their cart but had no recorded purchase.

### Checkout → Purchase

**5,296 users** started checkout but had no recorded purchase.

These groups represent potential areas for deeper investigation into product engagement, checkout behavior, payment behavior, and conversion recovery.

The available data does not establish the specific reasons for these behaviors.

---

# ⚠️ Data Quality & Limitations

Several limitations were identified during the analysis:

* The GA4 dataset is obfuscated and contains anonymized values.
* Some country values are `(not set)`.
* Some traffic-source values appear as `(data deleted)` or `<Other>`.
* Product names can appear under multiple product IDs.
* Traffic-source fields were not included in the cleaned event table and required analysis from the raw GA4 data.
* Unique purchasing users and completed orders are different metrics.
* Some users appear at multiple funnel stages without a perfectly sequential event path.
* The customer model uses an observed country value rather than a definitive primary country.
* Product-level price analysis showed association, not causation.
* Revenue reconciliation between order-level and item-level data showed a small discrepancy.

These limitations were documented rather than hidden so that the analysis remains transparent.

---

# 📁 Repository Structure

```text
E-Commerce-Revenue-Recovery/
│
├── 01_exploration.sql
├── 02_cleaning.sql
├── 03_data_model.sql
├── 04_business_analysis.sql
│
├── PROJECT_DOCUMENTATION.md
├── README.md
│
├── data/
│   └── README.md
│
└── dashboard/
```

The `dashboard/` folder is reserved for potential future visualization work. The current project focuses on SQL-based data exploration, transformation, modeling, and business analysis.

---

# 🎓 Skills Demonstrated

This project demonstrates practical experience with:

* SQL data exploration
* Data cleaning
* Nested and repeated GA4 data
* `UNNEST`
* CTEs
* Joins
* Window functions
* Data modeling
* Funnel analysis
* Customer analysis
* Product analysis
* Revenue analysis
* Data-quality validation
* Correlation analysis
* Business interpretation
* Analytical documentation
* BigQuery

---

# 👩🏾‍💻 Author

**Mylene Gadeau**

Aspiring Data Analyst | SQL | Excel | Python | Data Analysis

GitHub:
https://github.com/mylenegadeau-lang

LinkedIn:
https://www.linkedin.com/in/nicole-gadeau

