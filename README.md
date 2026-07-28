/* ============================================================================
   ZOMATO ORDER DATA ANALYSIS
   ----------------------------------------------------------------------------
   Author   : Pranav Khanna
   Database : PostgreSQL
   Purpose  : End-to-end SQL analysis of Zomato order data covering revenue,
              customer behavior, restaurant performance, and churn.

   Sections:
     1. Database Setup & Data Import
     2. Revenue Analysis
     3. Customer Analysis
     4. Restaurant Performance
     5. Churn Analysis
   ============================================================================ */


/* ============================================================================
   SECTION 1: DATABASE SETUP & DATA IMPORT
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- 1.1 Customers Table
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id          VARCHAR(50) PRIMARY KEY,
    customer_name        VARCHAR(15),
    city                 VARCHAR(10),
    signup_time          DATE,
    acquisition_channel  VARCHAR(20)
);

SET datestyle = 'ISO, DMY';

-- Import customer data
COPY customers
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Customer.csv'
DELIMITER ','
CSV HEADER
NULL '';

SELECT * FROM customers;


-- ---------------------------------------------------------------------------
-- 1.2 Orders Table
-- ---------------------------------------------------------------------------
CREATE TABLE zomato_orders (
    order_id          VARCHAR(50) PRIMARY KEY,
    customer_id       VARCHAR(50),
    restaurant_id     VARCHAR(50),
    order_timestamp   DATE,
    order_amount      DECIMAL(10,2),
    discount_amount   DECIMAL(10,2),
    delivery_fee      INT,
    payment_mode      VARCHAR(50),
    order_status      VARCHAR(50)
);

SET datestyle = 'ISO, DMY';

-- Import order data
COPY zomato_orders
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Orders.csv'
DELIMITER ','
CSV HEADER
NULL '';

SELECT * FROM zomato_orders;


-- ---------------------------------------------------------------------------
-- 1.3 Restaurants Table
-- ---------------------------------------------------------------------------
CREATE TABLE zomato_restaurants (
    restaurant_id     VARCHAR(50) PRIMARY KEY,
    restaurant_name   VARCHAR(100),
    cuisine           VARCHAR(100),
    city              VARCHAR(50),
    avg_rating        DECIMAL(3,1)
);

-- Import restaurant data
COPY zomato_restaurants
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Restaurants.csv'
DELIMITER ','
CSV HEADER
NULL '';

SELECT * FROM zomato_restaurants;



/* ============================================================================
   SECTION 2: REVENUE ANALYSIS
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- 2.1 What is the total revenue?
-- ---------------------------------------------------------------------------
SELECT
    SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered';


-- ---------------------------------------------------------------------------
-- 2.2 What are the monthly sales trends?
-- ---------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', order_timestamp) AS month,
    SUM(order_amount)                    AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', order_timestamp)
ORDER BY month;


-- ---------------------------------------------------------------------------
-- 2.3 Which city contributes the highest revenue?
-- ---------------------------------------------------------------------------
SELECT
    c.city,
    SUM(o.order_amount) AS total_revenue
FROM customers c
JOIN zomato_orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.city
ORDER BY total_revenue DESC;


-- ---------------------------------------------------------------------------
-- 2.4 Which payment mode generates the most revenue?
-- ---------------------------------------------------------------------------
SELECT
    payment_mode,
    SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY payment_mode
ORDER BY total_revenue DESC;


-- ---------------------------------------------------------------------------
-- 2.5 What is the Average Order Value (AOV)?
-- ---------------------------------------------------------------------------
SELECT
    SUM(order_amount) / COUNT(DISTINCT order_id) AS average_order_value
FROM zomato_orders
WHERE order_status = 'Delivered';


-- ---------------------------------------------------------------------------
-- 2.6 Who are the top 20 customers by revenue?
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 2.7 What percentage of revenue comes from the top 20 customers?
-- ---------------------------------------------------------------------------
WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(order_amount) AS total_revenue
    FROM zomato_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
top_20_customers AS (
    SELECT
        customer_id,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM customer_revenue
    QUALIFY rnk <= 20
)
SELECT
    ROUND(
        SUM(total_revenue) * 100.0 /
        (SELECT SUM(order_amount) FROM zomato_orders WHERE order_status = 'Delivered'),
        2
    ) AS pct_revenue_from_top_20
FROM top_20_customers;

-- NOTE: QUALIFY is not supported in PostgreSQL. If running on Postgres,
-- use the WHERE rnk <= 20 filter inside an outer SELECT instead (see 2.6 pattern).


-- ---------------------------------------------------------------------------
-- 2.8 Which acquisition channel brings the highest number of customers?
-- ---------------------------------------------------------------------------
SELECT
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS total_customers
FROM customers
GROUP BY acquisition_channel
ORDER BY total_customers DESC;


-- ---------------------------------------------------------------------------
-- 2.9 How many repeat customers do we have, by month?
-- ---------------------------------------------------------------------------
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



/* ============================================================================
   SECTION 3: RESTAURANT PERFORMANCE
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- 3.1 Which restaurant generates the highest revenue?
-- ---------------------------------------------------------------------------
SELECT
    r.restaurant_name,
    SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC;


-- ---------------------------------------------------------------------------
-- 3.2 Which restaurant gets the most orders?
-- ---------------------------------------------------------------------------
SELECT
    restaurant_id,
    COUNT(DISTINCT order_id) AS total_orders
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_id
ORDER BY total_orders DESC;


-- ---------------------------------------------------------------------------
-- 3.3 Which cuisine is most popular (by revenue)?
-- ---------------------------------------------------------------------------
SELECT
    r.cuisine,
    SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE o.order_status = 'Delivered'
GROUP BY r.cuisine
ORDER BY total_revenue DESC;


-- ---------------------------------------------------------------------------
-- 3.4 Do highly-rated restaurants generate the most revenue?
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 3.5 Which are the bottom 5 restaurants by revenue?
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 3.6 What is the overall cancellation rate and refund rate?
-- ---------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id) AS cancellation_rate,
    COUNT(DISTINCT CASE WHEN order_status = 'Refunded' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id) AS refund_rate
FROM zomato_orders;


-- ---------------------------------------------------------------------------
-- 3.7 Which restaurant has the highest cancellation rate?
-- ---------------------------------------------------------------------------
SELECT
    restaurant_id,
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id) AS cancellation_rate
FROM zomato_orders
GROUP BY restaurant_id
ORDER BY cancellation_rate DESC;



/* ============================================================================
   SECTION 4: CHURN ANALYSIS
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- 4.1 How many customers have churned? (inactive for 90+ days)
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 4.2 What is the overall customer churn rate?
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 4.3 Which city has the highest churn?
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 4.4 How much revenue is lost due to churn?
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- 4.5 Who are the top 10 highest-value churned customers?
-- ---------------------------------------------------------------------------
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

/* ============================================================================
   END OF FILE
   ============================================================================ */
