/* ====================================================================================
                                🍽️ ZOMATO DATA ANALYSIS 
=======================================================================================
   Author: Pranav Khanna
   Description: End-to-end SQL analysis of Zomato delivery data including 
                revenue trends, restaurant performance, and customer churn.
==================================================================================== */


/* ====================================================================================
   DATABASE SCHEMA & SETUP
==================================================================================== */

-- 1. Customers Table
CREATE TABLE customers(
    Cutomer_id VARCHAR(50) PRIMARY KEY,
    Cutomer_name VARCHAR(15),
    City VARCHAR(10),
    Signup_Time DATE,
    Acquisition_channel VARCHAR(20)
);

SET datestyle = 'ISO, DMY';

COPY customers
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Customer.csv'
DELIMITER ','
CSV HEADER
NULL '';


-- 2. Orders Table
CREATE TABLE zomato_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    restaurant_id VARCHAR(50),
    order_timestamp DATE,
    order_amount DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    delivery_fee INT,
    payment_mode VARCHAR(50),
    order_status VARCHAR(50)
);

SET datestyle = 'ISO, DMY';

COPY zomato_orders
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Orders.csv'
DELIMITER ','
CSV HEADER
NULL '';


-- 3. Restaurants Table
CREATE TABLE zomato_restaurants (
    restaurant_id VARCHAR(50) PRIMARY KEY,
    restaurant_name VARCHAR(100),
    cuisine VARCHAR(100),
    city VARCHAR(50),
    avg_rating DECIMAL(3,1)
);

COPY zomato_restaurants
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Restaurants.csv'
DELIMITER ','
CSV HEADER
NULL '';


/* ====================================================================================
   SECTION 1: REVENUE & SALES ANALYSIS
==================================================================================== */

/* Q1: What is the total revenue? */
SELECT SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered';


/* Q2: What are the monthly sales? */
SELECT 
    DATE_TRUNC('month', order_timestamp) AS Month, 
    SUM(order_amount) AS Total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', order_timestamp)
ORDER BY Month;


/* Q3: Which city contributes the highest revenue? */
SELECT
    c.City,
    SUM(o.order_amount) AS total_revenue
FROM customers c
JOIN zomato_orders o
    ON c.Cutomer_id = o.customer_id
WHERE order_status = 'Delivered'
GROUP BY City
ORDER BY total_revenue DESC;


/* Q4: Which payment mode generates the most revenue? */
SELECT
    payment_mode,
    SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY payment_mode
ORDER BY total_revenue DESC;


/* Q5: What is the average order value (AOV)? */
SELECT 
    SUM(order_amount)/COUNT(DISTINCT order_id) AS average_order_value 
FROM zomato_orders
WHERE order_status = 'Delivered';


/* ====================================================================================
   SECTION 2: CUSTOMER BEHAVIOR & COHORT ANALYSIS
==================================================================================== */

/* Q6: Who are the top 20 customers by revenue? */
WITH cte AS (
    SELECT customer_id, SUM(order_amount) AS Total_revenue
    FROM zomato_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT customer_id, Total_revenue, "rank" 
FROM (
    SELECT customer_id, cte.Total_revenue, ROW_NUMBER() OVER(ORDER BY Total_revenue DESC) AS "rank" 
    FROM cte
) b
WHERE "rank" <= 20;


/* Q7: What percentage of revenue comes from the top customers? */
WITH cte AS (
    SELECT customer_id, SUM(order_amount) AS Total_revenue
    FROM zomato_orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
cte2 AS (
    SELECT customer_id, Total_revenue, "rank" 
    FROM (
        SELECT customer_id, cte.Total_revenue, ROW_NUMBER() OVER(ORDER BY Total_revenue DESC) AS "rank" 
        FROM cte
    ) b
    WHERE "rank" <= 20
)
SELECT 
    ROUND(SUM(Total_revenue) * 100.0 / (
        SELECT SUM(order_amount)
        FROM zomato_orders
        WHERE order_status = 'Delivered'
    ), 2) AS pct_of_top_20_contribution
FROM cte2;


/* Q8: Which acquisition channel brings the highest-value customers? */
SELECT 
    Acquisition_channel,
    COUNT(DISTINCT Cutomer_id) AS total_customers
FROM customers
GROUP BY Acquisition_channel
ORDER BY total_customers DESC;


/* Q9: How many repeat customers do we have per month? */
WITH first_orders AS (
    SELECT 
        customer_id,
        MIN(order_timestamp) AS first_time 
    FROM zomato_orders
    GROUP BY customer_id
)
SELECT 
    DATE_TRUNC('month', a.order_timestamp) AS Month,
    COUNT(DISTINCT a.customer_id) AS returning_customers
FROM zomato_orders a
JOIN first_orders b 
    ON a.customer_id = b.customer_id 
    AND DATE_TRUNC('month', a.order_timestamp) > DATE_TRUNC('month', b.first_time)
GROUP BY 1
ORDER BY Month DESC;


/* ====================================================================================
   SECTION 3: RESTAURANT PERFORMANCE
==================================================================================== */

/* Q10: Which restaurant generates the highest revenue? */
SELECT
    r.restaurant_name,
    SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC;


/* Q11: Which restaurant gets the most orders? */
SELECT 
    restaurant_id, 
    COUNT(DISTINCT order_id) AS Total_orders
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_id
ORDER BY Total_orders DESC;


/* Q12: Which cuisine is the most popular? */
SELECT
    r.cuisine,
    SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY r.cuisine
ORDER BY total_revenue DESC;


/* Q13: Do highly rated restaurants generate the most revenue? */
SELECT 
    r.restaurant_name,
    ROUND(AVG(r.avg_rating), 2) AS avg_rating,
    SUM(o.order_amount) AS Total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
    ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY r.restaurant_name, avg_rating
ORDER BY Total_revenue DESC;


/* Q14: What are the bottom 5 restaurants by revenue? */
WITH cte AS (
    SELECT 
        r.restaurant_name,
        ROUND(AVG(r.avg_rating), 2) AS avg_rating,
        SUM(o.order_amount) AS Total_revenue
    FROM zomato_orders o
    JOIN zomato_restaurants r
        ON r.restaurant_id = o.restaurant_id
    WHERE order_status = 'Delivered'
    GROUP BY r.restaurant_name
)
SELECT restaurant_name 
FROM (
    SELECT restaurant_name, Total_revenue, ROW_NUMBER() OVER (ORDER BY Total_revenue ASC) AS rnk 
    FROM cte
) b
WHERE rnk <= 5;


/* Q15: What is the overall cancellation and refund rate? */
SELECT 
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) * 100.0 / COUNT(DISTINCT order_id) AS canc_rate,
    COUNT(DISTINCT CASE WHEN order_status = 'Refunded' THEN order_id END) * 100.0 / COUNT(DISTINCT order_id) AS refund_rate
FROM zomato_orders;


/* Q16: Which restaurant has the highest cancellation rate? */
SELECT 
    restaurant_id,
    COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END) * 100.0 / COUNT(DISTINCT order_id) AS canc_rate
FROM zomato_orders
GROUP BY restaurant_id
ORDER BY canc_rate DESC;


/* ====================================================================================
   SECTION 4: CHURN ANALYSIS
==================================================================================== */

/* Q17: How many customers have churned (90+ days no order)? */
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),
cust_last AS (
    SELECT 
        customer_id,
        MAX(order_timestamp) AS max_txn_date
    FROM zomato_orders
    GROUP BY customer_id
)
SELECT COUNT(*) AS inactive_customers
FROM cust_last a
CROSS JOIN global_last b
WHERE (b.last_txn_date - a.max_txn_date) > 90;


/* Q18: What is the customer churn rate? */
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),
cust_last AS (
    SELECT 
        customer_id,
        MAX(order_timestamp) AS max_txn_date
    FROM zomato_orders
    GROUP BY customer_id
),
churn AS (
    SELECT *,
        CASE 
            WHEN (b.last_txn_date - a.max_txn_date) > 90 THEN 1 
            ELSE 0 
        END AS is_churn_tag
    FROM cust_last a
    CROSS JOIN global_last b
)
SELECT
    SUM(is_churn_tag) * 100.0 / COUNT(*) AS Customer_churn_rate 
FROM churn;


/* Q19: Which city has the highest churn? */
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),
cust_last AS (
    SELECT 
        a.customer_id,
        b.City,
        MAX(a.order_timestamp) AS max_txn_date
    FROM zomato_orders a
    JOIN customers b
        ON b.Cutomer_id = a.customer_id
    GROUP BY a.customer_id, b.City
)
SELECT 
    City, 
    COUNT(*) AS inactive_customers
FROM cust_last a
CROSS JOIN global_last b
WHERE (b.last_txn_date - a.max_txn_date) > 90
GROUP BY City
ORDER BY COUNT(*) DESC;


/* Q20: How much revenue is lost due to churn? */
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),
cust_last AS (
    SELECT 
        customer_id,
        MAX(order_timestamp) AS max_txn_date
    FROM zomato_orders
    GROUP BY customer_id
),
churn AS (
    SELECT a.customer_id
    FROM cust_last a
    CROSS JOIN global_last b
    WHERE (b.last_txn_date - a.max_txn_date) > 90
)
SELECT
    SUM(order_amount) AS revenue_loss
FROM zomato_orders
WHERE customer_id IN (SELECT customer_id FROM churn);


/* Q21: Who are the highest churned customers by revenue loss? */
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),
cust_last AS (
    SELECT 
        customer_id,
        MAX(order_timestamp) AS max_txn_date
    FROM zomato_orders
    GROUP BY customer_id
),
churn AS (
    SELECT a.customer_id
    FROM cust_last a
    CROSS JOIN global_last b
    WHERE (b.last_txn_date - a.max_txn_date) > 90
)
SELECT
    customer_id,
    SUM(order_amount) AS revenue_loss
FROM zomato_orders
WHERE customer_id IN (SELECT customer_id FROM churn)
GROUP BY customer_id
ORDER BY SUM(order_amount) DESC
LIMIT 10;
