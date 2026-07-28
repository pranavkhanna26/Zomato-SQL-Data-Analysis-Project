CREATE TABLE customers(
Cutomer_id VARCHAR(50) PRIMARY KEY,
Cutomer_name VARCHAR(15),
City VARCHAR(10),
Signup_Time DATE,
Acquisition_channel VARCHAR(20)
);
SET datestyle = 'ISO, DMY';

-- Import the data
COPY customers
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Customer.csv'
DELIMITER ','
CSV HEADER
NULL''

SELECT * FROM customers

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

SELECT * FROM zomato_orders;

-- Import the data
COPY zomato_orders
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Orders.csv'
DELIMITER ','
CSV HEADER
NULL '';

CREATE TABLE zomato_restaurants (
    restaurant_id VARCHAR(50) PRIMARY KEY,
    restaurant_name VARCHAR(100),
    cuisine VARCHAR(100),
    city VARCHAR(50),
    avg_rating DECIMAL(3,1)
);

-- Import the data
COPY zomato_restaurants
FROM 'C:\temp\Zomato_project_data\Zomato  Order Data.xlsx - Restaurants.csv'
DELIMITER ','
CSV HEADER
NULL '';

SELECT * FROM zomato_restaurants;

-- Revenue Analysis
--1. What is the total Revenue

SELECT SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered';

--2. Monthly sales

SELECT 
	DATE_TRUNC('month', order_timestamp) AS Month, 
	SUM(order_amount) AS Total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY DATE_TRUNC('month', order_timestamp)
ORDER BY Month;

-- which citry contribute the highest revenue
SELECT
		c.City,SUM(o.order_amount) AS total_revenue
FROM customers c
JOIN zomato_orders o
ON c.Cutomer_id = o.customer_id
WHERE order_status = 'Delivered'
GROUP BY City
ORDER BY total_revenue DESC;

--Which payment mode generate the most revenue
SELECT
		payment_mode,SUM(order_amount) AS total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY payment_mode
ORDER BY total_revenue DESC;

--What is average order value(AOV)
SELECT SUM(order_amount)/count(distinct order_id) as average_order_value 
FROM zomato_orders
WHERE order_status = 'Delivered';

-- Top 20 customer by revenue
WITH cte as(
SELECT customer_id, SUM(order_amount) AS Total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY customer_id)

SELECT customer_id,Total_revenue, "rank" FROM(
SELECT customer_id,cte.Total_revenue,row_number() OVER(ORDER BY Total_revenue DESC) AS "rank" FROM cte) b
WHERE "rank" <= 20

--What percetage of revenue comes from top customers
WITH cte as(
SELECT customer_id, SUM(order_amount) AS Total_revenue
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY customer_id),

cet2 AS
(SELECT customer_id,Total_revenue, "rank" FROM(
SELECT customer_id,cte.Total_revenue,row_number() OVER(ORDER BY Total_revenue DESC) AS "rank" FROM cte) b
WHERE "rank" <= 20)

SELECT ROUND(SUM(Total_revenue) * 100/(select SUM(order_amount)
	FROM zomato_orders
	WHERE order_status = 'Delivered'),2)
	FROM cet2

--Which acquisition channel bring the highest-value customer
SELECT Acquisition_channel,
		COUNT(DISTINCT Cutomer_id) AS total_customers
FROM customers
GROUP BY Acquisition_channel
ORDER BY total_customers DESC;

-- How many repeat customers do we have
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

-- RESTAURANT PERFORMANCE
-- which restaurent generate the highest REVENUE
SELECT
		r.restaurant_name,SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY restaurant_name
ORDER BY total_revenue DESC;

--Which restorant gets most orders
SELECT restaurant_id, COUNT(DISTINCT order_id) AS Total_orders
FROM zomato_orders
WHERE order_status = 'Delivered'
GROUP BY restaurant_id
ORDER BY Total_orders DESC;

--Which cusine is most popular
SELECT
		r.cuisine,SUM(o.order_amount) AS total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY cuisine
ORDER BY total_revenue DESC;

--Do highly rate restaurants generate most revene
SELECT 
		r.restaurant_name,
		ROUND(AVG(r.avg_rating),2) AS avg_rating,
		SUM(o.order_amount) AS Total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY restaurant_name,avg_rating
ORDER BY total_revenue DESC;

--Last 5 restaurant
WITH cte as(SELECT 
		r.restaurant_name,
		ROUND(AVG(r.avg_rating),2) AS avg_rating,
		SUM(o.order_amount) AS Total_revenue
FROM zomato_orders o
JOIN zomato_restaurants r
ON r.restaurant_id = o.restaurant_id
WHERE order_status = 'Delivered'
GROUP BY restaurant_name
ORDER BY total_revenue DESC)

SELECT restaurant_name from(
SELECT restaurant_name, Total_revenue, row_number() OVER (ORDER BY Total_revenue asc) as rnk from cte) b
WHERE rnk <=5 

--Which restaurant have the highest cancelation rate,refund rate

SELECT COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END)* 100/COUNT(DISTINCT order_id) AS canc_rate,
COUNT(DISTINCT CASE WHEN order_status = 'Refunded' THEN order_id END)* 100/COUNT(DISTINCT order_id) AS refund_rate
FROM zomato_orders

-- Which restaurant have highest cancelation rate
SELECT 
		restaurant_id,
		COUNT(DISTINCT CASE WHEN order_status = 'Cancelled' THEN order_id END)* 100/COUNT(DISTINCT order_id) AS canc_rate
FROM zomato_orders
GROUP BY restaurant_id
ORDER BY canc_rate DESC

--How many customers have churned
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

--What is the customer churned rate

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
churn AS(
SELECT *,
CASE 
	WHEN (b.last_txn_date - a.max_txn_date) > 90 
	THEN 1 ELSE 0 END AS is_churn_tag
FROM cust_last a
CROSS JOIN global_last b)

SELECT
SUM(is_churn_tag)* 100/count(*) as Customer_churn_rate FROM churn

--Which city has the highest churn

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
    GROUP BY customer_id, city
)

SELECT City, COUNT(*) AS inactive_customers
FROM cust_last a
CROSS JOIN global_last b
WHERE (b.last_txn_date - a.max_txn_date) > 90
GROUP BY city
ORDER BY count(*) DESC;

-- How my revenue is loss due to churn

WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),

cust_last AS (
    SELECT 
        customer_id,
        MAX(order_timestamp) AS max_txn_date
    FROM zomato_orders
    GROUP BY customer_id)
,

Churn AS(
SELECT customer_id
FROM cust_last a
CROSS JOIN global_last b
WHERE (b.last_txn_date - a.max_txn_date) > 90)

SELECT
		SUM(order_amount) AS revenue_loss
FROM zomato_orders
WHERE customer_id 
		in (SELECT customer_id FROM churn);


-- How are the highest Churn customers
WITH global_last AS (
    SELECT MAX(order_timestamp) AS last_txn_date 
    FROM zomato_orders
),

cust_last AS (
    SELECT 
        customer_id,
        MAX(order_timestamp) AS max_txn_date
    FROM zomato_orders
    GROUP BY customer_id)
,

Churn AS(
SELECT customer_id
FROM cust_last a
CROSS JOIN global_last b
WHERE (b.last_txn_date - a.max_txn_date) > 90)

SELECT
		customer_id,
		SUM(order_amount) AS revenue_loss
FROM zomato_orders
WHERE customer_id 
		in (SELECT customer_id FROM churn)
GROUP BY customer_id
ORDER BY SUM(order_amount) DESC
LIMIT 10;

