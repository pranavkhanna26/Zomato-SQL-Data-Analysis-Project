## 📌 1. Business Problem

Zomato is one of India's largest food delivery platforms, connecting millions of customers with restaurants across multiple cities.

Over the last few months, leadership has noticed a concerning pattern: the number of registered customers keeps growing, but **overall business performance isn't scaling with it**. Revenue growth has become inconsistent, customer retention appears to be slipping, and some restaurant partners are underperforming.

As the Data Analyst brought in to investigate, the objective is to analyze customer, restaurant, and order data to answer leadership's key questions and turn raw transactional data into **actionable business insights**.

---

## 🗂️ 2. Dataset

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

**Tools used:** PostgreSQL · SQL · CSV bulk import via `COPY`

---

## 🧠 3. SQL Analysis

Wrote SQL queries directly against the PostgreSQL tables to answer each business question, grouped into five focus areas: **Revenue, Customers, Restaurants, Cancellations & Refunds, and Churn.**

### 💰 Revenue Analysis

**Total Revenue:**
```sql
SELECT
    SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered';
```

**Monthly Revenue Trend:**
```sql
SELECT
    DATE_TRUNC('month', order_timestamp) AS month,
    SUM(order_amount)                    AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', order_timestamp)
ORDER BY month;
```

**Highest Revenue-Contributing City:**
```sql
SELECT
    c.city,
    SUM(o.order_amount) AS total_revenue
FROM customers c
JOIN zomato_orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city
ORDER BY total_revenue DESC;
```

**Revenue by Payment Mode:**
```sql
SELECT
    payment_mode,
    SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY payment_mode
ORDER BY total_revenue DESC;
```

**Average Order Value (AOV):**
```sql
SELECT
    SUM(order_amount) / COUNT(DISTINCT order_id) AS average_order_value
FROM zomato_orders
WHERE order_status = 'Delivered';
```

---

### 👤 Customer Analysis

**Top 20 Customers by Revenue:**
```sql
WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(order_amount) AS total_revenue
    FROM zomato_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM customer_revenue
)
SELECT
    customer_id,
    total_revenue,
    rnk
FROM ranked_customers
WHERE rnk <= 20;
```

**% of Revenue from Top 20 Customers:**
```sql
WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(order_amount) AS total_revenue
    FROM zomato_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM customer_revenue
),
top_20_customers AS (
    SELECT customer_id, total_revenue
    FROM ranked_customers
    WHERE rnk <= 20
)
SELECT
    ROUND(
        SUM(total_revenue) * 100.0 /
        (SELECT SUM(order_amount) FROM zomato_orders WHERE order_status = 'Delivered'),
        2
    ) AS pct_revenue_from_top_20
FROM top_20_customers;
```

**Acquisition Channel Bringing the Most Customers:**
```sql
SELECT
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS total_customers
FROM customers
GROUP BY acquisition_channel
ORDER BY total_customers DESC;
```

**Repeat Customers per Month:**
```sql
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_timestamp) AS first_order_date
    FROM zomato_orders
    GROUP BY customer_id
)
SELECT
    DATE_TRUNC('month', o.order_timestamp) AS month,
    COUNT(DISTINCT o.customer_id)          AS returning_customers
FROM zomato_orders o
JOIN first_orders f
    ON o.customer_id = f.customer_id
    AND DATE_TRUNC('month', o.order_timestamp) > DATE_TRUNC('month', f.first_order_date)
GROUP BY month
ORDER BY month DESC;
```

---

### 🏪 Restaurant Performance

**Highest Revenue-Generating Restaurants:**
```sql
SELECT
    r.restaurant_name,
    SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC;
```

**Restaurants with the Most Orders:**
```sql
SELECT
    restaurant_id,
    COUNT(DISTINCT order_id) AS total_orders
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_id
ORDER BY total_orders DESC;
```

**Most Popular Cuisine (by Revenue):**
```sql
SELECT
    r.cuisine,
    SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.cuisine
ORDER BY total_revenue DESC;
```

**Do Highly-Rated Restaurants Generate More Revenue?**
```sql
SELECT
    r.restaurant_name,
    ROUND(AVG(r.avg_rating), 2) AS avg_rating,
    SUM(o.order_amount)         AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC;
```

**Bottom 5 Restaurants by Revenue:**
```sql
WITH restaurant_revenue AS (
    SELECT
        r.restaurant_name,
        SUM(o.order_amount) AS total_revenue
    FROM zomato_orders o
    JOIN zomato_restaurants r
        ON r.restaurant_id = o.restaurant_id
    WHERE o.order_status = 'Delivered'
    GROUP BY r.restaurant_name
),
ranked_restaurants AS (
    SELECT
        restaurant_name,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue ASC) AS rnk
    FROM restaurant_revenue
)
SELECT restaurant_name
FROM ranked_restaurants
WHERE rnk <= 5;
```

---

### ❌ Cancellation & Refund Analysis

**Overall Cancellation Rate & Refund Rate:**
```sql
SELECT
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id) AS cancellation_rate,
    COUNT(DISTINCT CASE WHEN order_status = 'Refunded' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id) AS refund_rate
FROM zomato_orders;
```

**Restaurant with the Highest Cancellation Rate:**
```sql
SELECT
    restaurant_id,
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id) AS cancellation_rate
FROM zomato_orders
GROUP BY restaurant_id
ORDER BY cancellation_rate DESC;
```

---

### 🔁 Customer Churn Analysis

**How Many Customers Have Churned (90+ Days Inactive):**
```sql
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date
    FROM zomato_orders
),
customer_last AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM zomato_orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS inactive_customers
FROM customer_last c
CROSS JOIN global_last g
WHERE (g.last_txn_date - c.last_order_date) > 90;
```

**Overall Customer Churn Rate:**
```sql
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date
    FROM zomato_orders
),
customer_last AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM zomato_orders
    GROUP BY customer_id
),
churn_flagged AS (
    SELECT
        c.*,
        CASE WHEN (g.last_txn_date - c.last_order_date) > 90 THEN 1 ELSE 0 END AS is_churned
    FROM customer_last c
    CROSS JOIN global_last g
)
SELECT
    SUM(is_churned) * 100.0 / COUNT(*) AS customer_churn_rate
FROM churn_flagged;
```

**City with the Highest Churn:**
```sql
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date
    FROM zomato_orders
),
customer_last AS (
    SELECT
        o.customer_id,
        c.city,
        MAX(o.order_timestamp) AS last_order_date
    FROM zomato_orders o
    JOIN customers c
        ON c.customer_id = o.customer_id
    GROUP BY o.customer_id, c.city
)
SELECT
    cl.city,
    COUNT(*) AS inactive_customers
FROM customer_last cl
CROSS JOIN global_last g
WHERE (g.last_txn_date - cl.last_order_date) > 90
GROUP BY cl.city
ORDER BY inactive_customers DESC;
```

**Revenue Lost Due to Churn:**
```sql
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date
    FROM zomato_orders
),
customer_last AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM zomato_orders
    GROUP BY customer_id
),
churned_customers AS (
    SELECT customer_id
    FROM customer_last c
    CROSS JOIN global_last g
    WHERE (g.last_txn_date - c.last_order_date) > 90
)
SELECT
    SUM(order_amount) AS revenue_loss
FROM zomato_orders
WHERE customer_id IN (SELECT customer_id FROM churned_customers);
```

**Top 10 Highest-Value Churned Customers:**
```sql
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date
    FROM zomato_orders
),
customer_last AS (
    SELECT
        customer_id,
        MAX(order_timestamp) AS last_order_date
    FROM zomato_orders
    GROUP BY customer_id
),
churned_customers AS (
    SELECT customer_id
    FROM customer_last c
    CROSS JOIN global_last g
    WHERE (g.last_txn_date - c.last_order_date) > 90
)
SELECT
    customer_id,
    SUM(order_amount) AS revenue_loss
FROM zomato_orders
WHERE customer_id IN (SELECT customer_id FROM churned_customers)
GROUP BY customer_id
ORDER BY revenue_loss DESC
LIMIT 10;
```
