-- =========================================
-- SALES DATA ANALYSIS PROJECT (SQL)
-- =========================================

-- -----------------------------------------
-- 1. RAW DATA INSPECTION
-- -----------------------------------------

SELECT * FROM sales_data LIMIT 10;

-- -----------------------------------------
-- 2. DATA CLEANING & TRANSFORMATION
-- -----------------------------------------

DROP TABLE IF EXISTS sales_clean;

CREATE TABLE sales_clean AS
SELECT
    "Row ID" AS row_id,
    "Order ID" AS order_id,

    -- Standardizing Date Format
    CASE
        WHEN "Order Date" LIKE '____-__-__' 
            THEN DATE("Order Date")

        WHEN "Order Date" LIKE '__-__-____'
            THEN DATE(
                SUBSTR("Order Date", 7, 4) || '-' ||
                SUBSTR("Order Date", 4, 2) || '-' ||
                SUBSTR("Order Date", 1, 2)
            )

        WHEN "Order Date" LIKE '%/%'
            THEN DATE(
                SUBSTR("Order Date", -4) || '-' ||
                printf('%02d', CAST(SUBSTR("Order Date", 1, INSTR("Order Date", '/')-1) AS INTEGER)) || '-' ||
                printf('%02d', CAST(SUBSTR("Order Date", INSTR("Order Date", '/')+1, 2) AS INTEGER))
            )

        ELSE NULL
    END AS order_date,

    "Ship Date" AS ship_date,
    "Ship Mode" AS ship_mode,
    "Customer ID" AS customer_id,
    "Customer Name" AS customer_name,
    Segment AS segment,
    Country AS country,
    City AS city,
    State AS state,
    "Postal Code" AS postal_code,
    Region AS region,
    "Product ID" AS product_id,
    Category AS category,
    "Sub-Category" AS sub_category,
    "Product Name" AS product_name,

    CAST(Sales AS REAL) AS sales,
    CAST(Quantity AS INTEGER) AS quantity,
    CAST(Discount AS REAL) / 100.0 AS discount,
    CAST(Profit AS REAL) AS profit

FROM sales_data;

-- -----------------------------------------
-- 3. DATA VALIDATION
-- -----------------------------------------

-- Check null dates
SELECT COUNT(*) 
FROM sales_clean 
WHERE order_date IS NULL;

-- -----------------------------------------
-- 4. BUSINESS METRICS
-- -----------------------------------------

SELECT 
    COUNT(*) AS total_orders,
    SUM(sales) AS total_revenue,
    SUM(profit) AS total_profit,
    AVG(sales) AS avg_order_value
FROM sales_clean;

-- -----------------------------------------
-- 5. CATEGORY PERFORMANCE
-- -----------------------------------------

SELECT 
    category,
    SUM(sales) AS revenue,
    SUM(profit) AS profit,
    SUM(quantity) AS total_units
FROM sales_clean
GROUP BY category
ORDER BY revenue DESC;

-- -----------------------------------------
-- 6. MONTHLY REVENUE TREND
-- -----------------------------------------

SELECT 
    STRFTIME('%Y-%m', order_date) AS month,
    SUM(sales) AS revenue
FROM sales_clean
GROUP BY month
ORDER BY month;

-- -----------------------------------------
-- 7. TOP PRODUCTS
-- -----------------------------------------

SELECT 
    product_name,
    SUM(sales) AS revenue
FROM sales_clean
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;

-- -----------------------------------------
-- 8. PARETO ANALYSIS (80/20)
-- -----------------------------------------

WITH product_revenue AS (
    SELECT 
        product_name,
        SUM(sales) AS revenue
    FROM sales_clean
    GROUP BY product_name
),
ranked AS (
    SELECT *,
           SUM(revenue) OVER () AS total_revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue
    FROM product_revenue
)
SELECT *,
       ROUND(cumulative_revenue * 1.0 / total_revenue, 2) AS cumulative_pct
FROM ranked;

-- -----------------------------------------
-- 9. DISCOUNT IMPACT ANALYSIS
-- -----------------------------------------

SELECT 
    discount,
    AVG(sales) AS avg_sales,
    AVG(profit) AS avg_profit,
    COUNT(*) AS orders
FROM sales_clean
GROUP BY discount
ORDER BY discount;
