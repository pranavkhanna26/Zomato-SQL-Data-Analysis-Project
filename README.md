# 🍽️ Zomato Customer & Business Analytics (SQL Case Study)

An end-to-end SQL case study analyzing Zomato's customer, order, and restaurant data to diagnose slowing growth, inconsistent revenue, and declining customer retention — and to surface actionable, data-driven recommendations.

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-success?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

---

## 📌 Business Problem

Zomato is one of India's largest food delivery platforms, connecting millions of customers with restaurants across multiple cities.

Over the last few months, leadership has noticed a concerning pattern: the number of registered customers keeps growing, but **overall business performance isn't scaling with it**. Revenue growth has become inconsistent, customer retention appears to be slipping, and some restaurant partners are underperforming.

As the Data Analyst brought in to investigate, the objective is to analyze customer, restaurant, and order data to answer leadership's key questions and turn raw transactional data into **actionable business insights**.

---

## 🎯 Objective

Use SQL to analyze the underlying data and answer questions across six focus areas:

1. **Revenue Analysis** — how much are we making, and where is it coming from?
2. **Customer Analysis** — who are our best customers, and how do we acquire them?
3. **Restaurant Performance** — which partners are driving (or dragging down) the business?
4. **Coupon Analysis** — are discounts actually helping us?
5. **Cancellation & Refund Analysis** — how much are we losing to failed orders?
6. **Customer Churn Analysis** — who's leaving, and what is it costing us?

---

## 🗂️ Dataset

The data comes from an Excel workbook (`Zomato Order Data.xlsx`) with three sheets — `Customer`, `Orders`, `Restaurants` — imported into PostgreSQL as three relational tables.

### `customers`
| Column               | Type          | Description                          |
|-----------------------|--------------|----------------------------------------|
| customer_id           | VARCHAR(50)  | Unique customer identifier (PK)        |
| customer_name         | VARCHAR(15)  | Customer's name                        |
| city                  | VARCHAR(10)  | Customer's city                        |
| signup_time           | DATE         | Date the customer signed up            |
| acquisition_channel   | VARCHAR(20)  | Channel through which customer joined  |

### `zomato_orders`
| Column            | Type           | Description                              |
|-------------------|---------------|--------------------------------------------|
| order_id          | VARCHAR(50)    | Unique order identifier (PK)               |
| customer_id       | VARCHAR(50)    | FK → customers                             |
| restaurant_id     | VARCHAR(50)    | FK → zomato_restaurants                    |
| order_timestamp   | DATE           | Date the order was placed                  |
| order_amount      | DECIMAL(10,2)  | Total order value                          |
| discount_amount   | DECIMAL(10,2)  | Discount / coupon value applied            |
| delivery_fee      | INT            | Delivery fee charged                       |
| payment_mode      | VARCHAR(50)    | Payment method used                        |
| order_status      | VARCHAR(50)    | Delivered / Cancelled / Refunded           |

### `zomato_restaurants`
| Column           | Type           | Description                    |
|------------------|---------------|----------------------------------|
| restaurant_id    | VARCHAR(50)    | Unique restaurant identifier (PK) |
| restaurant_name  | VARCHAR(100)   | Name of the restaurant           |
| cuisine          | VARCHAR(100)   | Cuisine type                     |
| city             | VARCHAR(50)    | City the restaurant operates in  |
| avg_rating       | DECIMAL(3,1)   | Average customer rating          |

**Entity relationship:**
```
customers (1) ───< (many) zomato_orders (many) >─── (1) zomato_restaurants
```

---

## 🛠️ Tools & Tech

- **Database:** PostgreSQL
- **Language:** SQL
- **Data Source:** CSV exports from an Excel workbook, bulk-loaded via `COPY`

---

## 🧩 SQL Concepts & Functions Used

This project was built entirely in SQL, applying a broad range of core and intermediate techniques:

| Category                     | Functions / Concepts Used                                                                 |
|-------------------------------|--------------------------------------------------------------------------------------------|
| **DDL (Schema Design)**       | `CREATE TABLE`, `PRIMARY KEY`, data types (`VARCHAR`, `DATE`, `DECIMAL`, `INT`)             |
| **Data Import**               | `COPY ... FROM`, `DELIMITER`, `CSV HEADER`, `NULL`, `SET datestyle`                         |
| **Aggregate Functions**       | `SUM()`, `COUNT()`, `COUNT(DISTINCT ...)`, `AVG()`, `MAX()`, `MIN()`                        |
| **Window Functions**          | `ROW_NUMBER() OVER (ORDER BY ...)` — used for ranking (top 20 customers, bottom 5 restaurants, top churned customers) |
| **Common Table Expressions**  | `WITH ... AS (...)` — including chained/nested CTEs for multi-step logic (e.g. churn analysis, revenue % calculations) |
| **Conditional Logic**         | `CASE WHEN ... THEN ... ELSE ... END` — used for cancellation/refund rates and churn flags |
| **Joins**                     | `INNER JOIN`, `CROSS JOIN`                                                                  |
| **Date/Time Functions**       | `DATE_TRUNC()`, date arithmetic (`date1 - date2`) for recency/churn windows                 |
| **Subqueries**                | Scalar subqueries (e.g. revenue % of top customers), `IN (SELECT ...)`                      |
| **Numeric Functions**         | `ROUND()`                                                                                    |
| **Filtering & Grouping**      | `WHERE`, `GROUP BY`, `ORDER BY`, `LIMIT`                                                     |
| **Set-based Ranking Pattern** | Ranking inside a CTE, then filtering with an outer `WHERE rnk <= N` (Postgres-safe alternative to `QUALIFY`) |

---

## 📊 Business Questions Answered

### 💰 Revenue Analysis
- What is the total revenue?
- What is the monthly revenue trend?
- Which city contributes the highest revenue?
- Which payment mode generates the most revenue?
- What is the Average Order Value (AOV)?

### 👤 Customer Analysis
- Who are the top 20 customers by revenue?
- What percentage of revenue comes from top customers?
- Which acquisition channel brings the highest-value customers?
- How many repeat customers do we have?

### 🏪 Restaurant Performance
- Which restaurants generate the highest revenue?
- Which restaurants receive the most orders?
- Which cuisines are most popular?
- Do highly-rated restaurants generate more revenue?
- Which are the bottom 5 restaurants by revenue?

### ❌ Cancellation & Refund Analysis
- What is the overall cancellation rate?
- What is the overall refund rate?
- Which restaurants have the highest cancellation rate?

### 🔁 Customer Churn Analysis
- How many customers have churned (90+ days inactive)?
- What is the overall customer churn rate?
- Which city has the highest churn?
- How much revenue is lost due to churn?
- Who are the top 10 highest-value churned customers?

### 🎟️ Coupon Analysis — *Planned / Not yet implemented*
The problem statement also calls for coupon-related insights (% of orders using coupons, coupon users vs. non-coupon spend, city-wise coupon usage, and coupon impact on retention). The `discount_amount` column supports this, but these queries aren't in the current script yet — see [Future Scope](#-future-scope).

---

## 📁 Repository Structure

```
├── zomato_data_analysis.sql   # Full SQL script (schema + import + all analysis queries)
└── README.md                 # Project documentation
```

---

## ▶️ How to Run

1. Install [PostgreSQL](https://www.postgresql.org/download/) and a client such as pgAdmin or `psql`.
2. Create a new database:
   ```sql
   CREATE DATABASE zomato_analysis;
   ```
3. Update the `COPY ... FROM` file paths in the script to point to your local CSV files.
4. Run `zomato_data_analysis.sql` section by section (schema creation → data import → analysis queries).

> **Note:** `COPY` requires the CSV files to be accessible to the PostgreSQL server itself, not just your client machine. If you don't have server-side file access, use `psql`'s `\copy` command instead, which reads from your local machine.

---

## 💡 Key Insights *(fill in with your actual results once you run the queries)*

- Total revenue generated: `₹ ___`
- Top revenue-generating city: `___`
- Most popular payment mode: `___`
- % of revenue from top 20 customers: `___%`
- Cancellation rate: `___%` | Refund rate: `___%`
- Customer churn rate: `___%`
- Revenue at risk from churned customers: `₹ ___`

---

## 🔭 Future Scope

- **Coupon Analysis**: build out the four coupon-related questions from the problem statement using `discount_amount` (e.g. `discount_amount > 0` as a coupon-usage flag).
- **Cancellation revenue impact**: quantify total revenue lost specifically to cancellations (separate from the churn revenue-loss metric already covered).
- Visualization layer (Power BI / Tableau) on top of these SQL outputs for a stakeholder-facing dashboard.

---

## 📌 Notes on Data Cleaning

- Standardized column names to lowercase/snake_case (e.g. `Cutomer_id` → `customer_id`) for consistency and to avoid quoting issues in PostgreSQL.
- All revenue-related metrics are filtered to `order_status = 'Delivered'` unless the query specifically analyzes cancellations or refunds.
- `QUALIFY` (used in Snowflake/BigQuery for ranking filters) isn't supported in PostgreSQL — the script instead ranks inside a CTE and filters with an outer `WHERE rnk <= N`.

---

## 🙋‍♂️ Author

**Pranav Khanna**
📧 pranavkhanna2602@gmail.com 🔗 https://www.linkedin.com/in/pranav-khanna-057360346/ | 

---

## 📄 License

This project is licensed under the MIT License — feel free to use and adapt it.
