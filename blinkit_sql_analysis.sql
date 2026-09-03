/* ==========================================================================
   BLINKIT SALES & DELIVERY PERFORMANCE ANALYSIS
   --------------------------------------------------------------------------
   Database : PostgreSQL
   Author   : Harshal
   Purpose  : SQL-based analysis of Blinkit's orders, customers, products,
              and order_items data to answer key business questions related
              to sales performance, delivery efficiency, and customer
              behavior. Results were cross-validated against the Python
              (Pandas) analysis in the accompanying Jupyter notebook.
   ========================================================================== */


-- ==========================================================================
-- 1. DATABASE SETUP
-- ==========================================================================

CREATE DATABASE blinkit_db;

-- Connect to blinkit_db before executing the statements below


-- ==========================================================================
-- 2. SCHEMA DEFINITION
-- ==========================================================================

CREATE TABLE customers (
    customer_id      SERIAL PRIMARY KEY,
    customer_name    VARCHAR,
    customer_segment VARCHAR,
    city              VARCHAR,
    signup_date       DATE
);

CREATE TABLE products (
    product_id   VARCHAR PRIMARY KEY,
    product_name VARCHAR,
    category     VARCHAR,
    price        NUMERIC
);

CREATE TABLE orders (
    order_id                BIGINT PRIMARY KEY,
    customer_id             INT REFERENCES customers(customer_id),
    order_date               TIMESTAMP,
    promised_delivery_time   TIMESTAMP,
    actual_delivery_time     TIMESTAMP,
    delivery_status          VARCHAR,
    order_total               NUMERIC,
    payment_method           VARCHAR,
    delivery_partner_id       BIGINT,
    store_id                  BIGINT,
    delivery_time_minutes    NUMERIC,
    delay_minutes             NUMERIC,
    is_late                   BOOLEAN,
    day_of_week               VARCHAR
);

CREATE TABLE order_items (
    order_item_id BIGINT PRIMARY KEY,
    order_id      BIGINT REFERENCES orders(order_id),
    product_id    VARCHAR REFERENCES products(product_id),
    quantity      INT
);


-- ==========================================================================
-- 3. DATA OVERVIEW & QUALITY CHECKS
-- ==========================================================================

-- Row counts across all tables
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Sample records from each table
SELECT * FROM customers LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM orders LIMIT 10;
SELECT * FROM order_items LIMIT 10;

-- Null value check on key columns
SELECT
    COUNT(*) FILTER (WHERE order_date IS NULL)          AS null_order_date,
    COUNT(*) FILTER (WHERE actual_delivery_time IS NULL) AS null_actual_delivery,
    COUNT(*) FILTER (WHERE order_total IS NULL)          AS null_order_total
FROM orders;

-- Duplicate record check
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ==========================================================================
-- 4. BUSINESS QUESTIONS
-- ==========================================================================

-- --------------------------------------------------------------------------
-- Q1. What is the distribution of orders across payment methods?
-- --------------------------------------------------------------------------
SELECT
    payment_method,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM orders
GROUP BY payment_method
ORDER BY order_count DESC;


-- --------------------------------------------------------------------------
-- Q2. What percentage of orders are delivered late, and what is the
--     average delay in minutes?
-- --------------------------------------------------------------------------
SELECT
    ROUND(AVG(delay_minutes), 2) AS avg_delay_minutes,
    ROUND(100.0 * SUM(CASE WHEN is_late THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_delivery_pct
FROM orders;


-- --------------------------------------------------------------------------
-- Q3. Which day of the week has the highest average delivery delay?
-- --------------------------------------------------------------------------
SELECT
    day_of_week,
    ROUND(AVG(delay_minutes), 2) AS avg_delay_minutes,
    COUNT(*)                     AS total_orders
FROM orders
GROUP BY day_of_week
ORDER BY avg_delay_minutes DESC;


-- --------------------------------------------------------------------------
-- Q4. What is the monthly trend in order volume and revenue?
-- --------------------------------------------------------------------------
SELECT
    "Month",
    COUNT(*)         AS total_orders,
    SUM(order_total) AS total_revenue
FROM orders
GROUP BY "Month"
ORDER BY "Month";


-- --------------------------------------------------------------------------
-- Q5. What is the overall breakdown of delivery status?
-- --------------------------------------------------------------------------
SELECT
    delivery_status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM orders
GROUP BY delivery_status
ORDER BY order_count DESC;


-- --------------------------------------------------------------------------
-- Q6. What are the top 10 best-selling products by quantity?
-- --------------------------------------------------------------------------
SELECT
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;


-- --------------------------------------------------------------------------
-- Q7. Which product category generates the highest revenue?
-- --------------------------------------------------------------------------
SELECT
    p.category,
    SUM(o.order_total) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;


-- --------------------------------------------------------------------------
-- Q8. How many customers are repeat buyers vs one-time buyers, and what
--     share of total revenue does each group contribute?
-- --------------------------------------------------------------------------
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(order_total)         AS total_spent
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*)                                                    AS num_customers,
    SUM(total_spent)                                            AS total_revenue,
    ROUND(100.0 * SUM(total_spent) / SUM(SUM(total_spent)) OVER (), 2) AS pct_of_revenue
FROM customer_orders
GROUP BY customer_type;


-- --------------------------------------------------------------------------
-- Q9. Who are the top 10 customers by total revenue contributed?
-- --------------------------------------------------------------------------
SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.order_total)         AS total_spent,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;


-- --------------------------------------------------------------------------
-- Q10. Do higher-value orders tend to experience longer delivery delays?
-- --------------------------------------------------------------------------
SELECT
    CASE
        WHEN order_total < 500  THEN 'Low (<500)'
        WHEN order_total < 1500 THEN 'Medium (500-1500)'
        ELSE 'High (>1500)'
    END AS order_value_bucket,
    ROUND(AVG(delay_minutes), 2) AS avg_delay_minutes,
    COUNT(*)                     AS total_orders
FROM orders
GROUP BY order_value_bucket
ORDER BY avg_delay_minutes DESC;


/* ==========================================================================
   END OF SCRIPT
   All queries above were cross-checked against the equivalent Pandas
   analysis in the Jupyter notebook to ensure consistent results across
   both tools.
   ========================================================================== */
