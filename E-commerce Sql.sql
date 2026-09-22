CREATE TABLE ecommerce_sales (
    row_id INT,
    order_id VARCHAR(30),
    year INT,
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(30),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name TEXT,
    sales NUMERIC(12,2),
    quantity INT,
    discount NUMERIC(5,2),
    profit NUMERIC(12,4)
);

--1. What is our total revenue so far?

SELECT SUM(sales) AS total_revenue
FROM ecommerce_sales;

--2. How many total orders have we received?

SELECT COUNT(DISTINCT order_id) AS total_orders
FROM ecommerce_sales;

--3. How many total customers do we have?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM ecommerce_sales;

--4. How many total products do we sell?
SELECT COUNT(DISTINCT product_id) AS total_products
FROM ecommerce_sales;

--5. What is the average amount a customer spends per order?
SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT order_id,
           SUM(sales) AS order_total
    FROM ecommerce_sales
    GROUP BY order_id
) AS order_summary;

--6. What are the top 5 best-selling products?
SELECT product_name,
       SUM(quantity) AS total_quantity_sold
FROM ecommerce_sales
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

--7. Which category is generating the most revenue?
SELECT category,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 1;

--8. Who are our top 5 most valuable customers?
SELECT customer_id,
       customer_name,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY customer_id, customer_name
ORDER BY total_revenue DESC
LIMIT 5;

--9. How has our revenue trended month by month?
SELECT EXTRACT(YEAR FROM order_date) AS order_year,
       EXTRACT(MONTH FROM order_date) AS order_month,
       ROUND(SUM(sales), 2) AS monthly_revenue
FROM ecommerce_sales
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

--10. Which city is generating the most sales?
SELECT city,
       ROUND(SUM(sales), 2) AS total_sales
FROM ecommerce_sales
GROUP BY city
ORDER BY total_sales DESC
LIMIT 1;

--11. Which customers purchase repeatedly?
SELECT customer_id,
       customer_name,
       COUNT(DISTINCT order_id) AS total_orders
FROM ecommerce_sales
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY total_orders DESC;

--12. Which customers have never placed an order?-- Requires a separate customers master table.
SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM ecommerce_sales
GROUP BY customer_id, customer_name
ORDER BY total_orders ASC;

--13. Which customers have been inactive in the last 90 days?
SELECT customer_id,
       customer_name,
       MAX(order_date) AS last_order_date
FROM ecommerce_sales
GROUP BY customer_id, customer_name
HAVING MAX(order_date) < (
    SELECT MAX(order_date) - INTERVAL '90 days'
    FROM ecommerce_sales
);

--14. What is the best-selling category?
SELECT category,
       SUM(quantity) AS total_quantity_sold
FROM ecommerce_sales
GROUP BY category
ORDER BY total_quantity_sold DESC
LIMIT 1;

--15. Which product generates the highest revenue?
SELECT product_name,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 1;

--16. Which product generates the lowest revenue?
SELECT product_name,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY product_name
ORDER BY total_revenue ASC
LIMIT 1;

--17. On average, how many products are bought per order?
SELECT ROUND(AVG(total_quantity), 2) AS average_products_per_order
FROM (
    SELECT order_id,
           SUM(quantity) AS total_quantity
    FROM ecommerce_sales
    GROUP BY order_id
) AS order_summary;

--18. Which orders are worth more than 10,000?
SELECT order_id,
       ROUND(SUM(sales), 2) AS order_value
FROM ecommerce_sales
GROUP BY order_id
HAVING SUM(sales) > 10000
ORDER BY order_value DESC;

--19. Which customers have the highest average order value?
WITH customer_orders AS (
    SELECT customer_id,
           customer_name,
           order_id,
           SUM(sales) AS order_value
    FROM ecommerce_sales
    GROUP BY customer_id, customer_name, order_id
)
SELECT customer_id,
       customer_name,
       ROUND(AVG(order_value), 2) AS average_order_value
FROM customer_orders
GROUP BY customer_id, customer_name
ORDER BY average_order_value DESC;

--20. What are the top 3 cities by revenue?
SELECT city,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY city
ORDER BY total_revenue DESC
LIMIT 3;

--21. How are customers ranked based on revenue?
SELECT customer_id,
       customer_name,
       ROUND(SUM(sales), 2) AS total_revenue,
       RANK() OVER (ORDER BY SUM(sales) DESC) AS revenue_rank
FROM ecommerce_sales
GROUP BY customer_id, customer_name;

--22. What is the top-selling product in each category?
WITH product_sales AS (
    SELECT category,
           product_name,
           SUM(quantity) AS total_quantity,
           ROW_NUMBER() OVER (
               PARTITION BY category
               ORDER BY SUM(quantity) DESC
           ) AS rn
    FROM ecommerce_sales
    GROUP BY category, product_name
)
SELECT category,
       product_name,
       total_quantity
FROM product_sales
WHERE rn = 1;

--23. How has our revenue accumulated over time (running total)?
WITH daily_revenue AS (
    SELECT order_date::date AS order_date,
           SUM(sales) AS daily_revenue
    FROM ecommerce_sales
    GROUP BY order_date::date
)
SELECT order_date,
       ROUND(daily_revenue, 2) AS daily_revenue,
       ROUND(
           SUM(daily_revenue) OVER (
               ORDER BY order_date
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ),
           2
       ) AS running_total_revenue
FROM daily_revenue
ORDER BY order_date;

--24. When was each customer's previous order placed?
SELECT customer_id,
       customer_name,
       order_id,
       order_date,
       LAG(order_date) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
       ) AS previous_order_date
FROM (
    SELECT DISTINCT customer_id,
           customer_name,
           order_id,
           order_date
    FROM ecommerce_sales
) AS orders;

--25. When was each customer's next order placed, if any?
SELECT customer_id,
       customer_name,
       order_id,
       order_date,
       LEAD(order_date) OVER (
           PARTITION BY customer_id
           ORDER BY order_date
       ) AS next_order_date
FROM (
    SELECT DISTINCT customer_id,
           customer_name,
           order_id,
           order_date
    FROM ecommerce_sales
) AS orders;

--26. How many days are there between a customer's consecutive orders?
WITH orders AS (
    SELECT DISTINCT customer_id,
           customer_name,
           order_id,
           order_date,
           LAG(order_date) OVER (
               PARTITION BY customer_id
               ORDER BY order_date
           ) AS previous_order_date
    FROM ecommerce_sales
)
SELECT customer_id,
       customer_name,
       order_id,
       order_date,
       order_date - previous_order_date AS days_between_orders
FROM orders
WHERE previous_order_date IS NOT NULL;

--27. Who are the top 3 customers by revenue?
SELECT customer_id,
       customer_name,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY customer_id, customer_name
ORDER BY total_revenue DESC
LIMIT 3;

--28. What percentage does each product contribute to total revenue?
SELECT product_name,
       ROUND(SUM(sales), 2) AS product_revenue,
       ROUND(
           SUM(sales) * 100.0 / SUM(SUM(sales)) OVER (),
           2
       ) AS revenue_contribution_percentage
FROM ecommerce_sales
GROUP BY product_name
ORDER BY product_revenue DESC;

--29. What is the month-over-month revenue growth?
WITH monthly_revenue AS (
    SELECT DATE_TRUNC('month', order_date)::date AS order_month,
           SUM(sales) AS monthly_revenue
    FROM ecommerce_sales
    GROUP BY DATE_TRUNC('month', order_date)::date
),
revenue_with_previous AS (
    SELECT order_month,
           monthly_revenue,
           LAG(monthly_revenue) OVER (
               ORDER BY order_month
           ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT order_month,
       ROUND(monthly_revenue, 2) AS monthly_revenue,
       ROUND(previous_month_revenue, 2) AS previous_month_revenue,
       ROUND(
           (monthly_revenue - previous_month_revenue)
           * 100.0 / NULLIF(previous_month_revenue, 0),
           2
       ) AS mom_growth_percentage
FROM revenue_with_previous
ORDER BY order_month;

--30. What was each customer's highest-value order?
WITH customer_orders AS (
    SELECT customer_id,
           customer_name,
           order_id,
           SUM(sales) AS order_value
    FROM ecommerce_sales
    GROUP BY customer_id, customer_name, order_id
),
ranked_orders AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY order_value DESC
           ) AS rn
    FROM customer_orders
)
SELECT customer_id,
       customer_name,
       order_id,
       ROUND(order_value, 2) AS order_value
FROM ranked_orders
WHERE rn = 1;

--31. What is each customer's lifetime value (CLV)?
SELECT customer_id,
       customer_name,
       ROUND(SUM(sales), 2) AS customer_lifetime_value
FROM ecommerce_sales
GROUP BY customer_id, customer_name
ORDER BY customer_lifetime_value DESC;

--32. What percentage of customers make repeat purchases?
WITH customer_orders AS (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS total_orders
    FROM ecommerce_sales
    GROUP BY customer_id
)
SELECT ROUND(
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
    * 100.0 / COUNT(*),
    2
) AS repeat_purchase_rate_percentage
FROM customer_orders;

--33. How many customers are new vs returning?
WITH customer_orders AS (
    SELECT customer_id,
           COUNT(DISTINCT order_id) AS total_orders
    FROM ecommerce_sales
    GROUP BY customer_id
)
SELECT CASE
           WHEN total_orders = 1 THEN 'New'
           ELSE 'Returning'
       END AS customer_type,
       COUNT(*) AS customer_count
FROM customer_orders
GROUP BY CASE
             WHEN total_orders = 1 THEN 'New'
             ELSE 'Returning'
         END;

--34. How many customers were active each month (retention)?
SELECT EXTRACT(YEAR FROM order_date) AS order_year,
       EXTRACT(MONTH FROM order_date) AS order_month,
       COUNT(DISTINCT customer_id) AS active_customers
FROM ecommerce_sales
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

--35. Which customers purchase from more than one category?
SELECT customer_id,
       customer_name,
       COUNT(DISTINCT category) AS categories_purchased
FROM ecommerce_sales
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT category) > 1;

--36. Which two products are most frequently purchased together?
SELECT a.product_name AS product_1,
       b.product_name AS product_2,
       COUNT(*) AS times_bought_together
FROM ecommerce_sales a
JOIN ecommerce_sales b
    ON a.order_id = b.order_id
   AND a.product_id < b.product_id
GROUP BY a.product_name, b.product_name
ORDER BY times_bought_together DESC
LIMIT 1;

--37. On average, how many days pass between a customer's orders?
WITH orders AS (
    SELECT DISTINCT customer_id,
           order_id,
           order_date,
           LAG(order_date) OVER (
               PARTITION BY customer_id
               ORDER BY order_date
           ) AS previous_order_date
    FROM ecommerce_sales
)
SELECT ROUND(
    AVG(order_date - previous_order_date),
    2
) AS average_days_between_orders
FROM orders
WHERE previous_order_date IS NOT NULL;

--38. Which product category is growing the fastest?
WITH category_revenue AS (
    SELECT category,
           EXTRACT(YEAR FROM order_date) AS order_year,
           SUM(sales) AS yearly_revenue
    FROM ecommerce_sales
    GROUP BY category, EXTRACT(YEAR FROM order_date)
),
growth AS (
    SELECT category,
           order_year,
           yearly_revenue,
           LAG(yearly_revenue) OVER (
               PARTITION BY category
               ORDER BY order_year
           ) AS previous_year_revenue
    FROM category_revenue
)
SELECT category,
       ROUND(
           (yearly_revenue - previous_year_revenue)
           * 100.0 / NULLIF(previous_year_revenue, 0),
           2
       ) AS growth_percentage
FROM growth
WHERE previous_year_revenue IS NOT NULL
ORDER BY growth_percentage DESC
LIMIT 1;

--39. Which customers are at risk of churn?
SELECT customer_id,
       customer_name,
       MAX(order_date) AS last_order_date
FROM ecommerce_sales
GROUP BY customer_id, customer_name
HAVING MAX(order_date) < (
    SELECT MAX(order_date) - INTERVAL '90 days'
    FROM ecommerce_sales
)
ORDER BY last_order_date;

--40. How do customers look based on RFM analysis?
WITH customer_rfm AS (
    SELECT customer_id,
           customer_name,
           MAX(order_date) AS last_order_date,
           COUNT(DISTINCT order_id) AS frequency,
           SUM(sales) AS monetary
    FROM ecommerce_sales
    GROUP BY customer_id, customer_name
),
rfm_base AS (
    SELECT *,
           (
               (SELECT MAX(order_date) FROM ecommerce_sales)
               - last_order_date
           ) AS recency
    FROM customer_rfm
)
SELECT customer_id,
       customer_name,
       recency,
       frequency,
       ROUND(monetary, 2) AS monetary,
       NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
       NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
       NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM rfm_base;

--41. What is the daily sales trend?
SELECT order_date::date AS order_date,
       ROUND(SUM(sales), 2) AS daily_sales
FROM ecommerce_sales
GROUP BY order_date::date
ORDER BY order_date;

--42. What are the top 10 best-selling products?
SELECT product_name,
       SUM(quantity) AS total_quantity_sold
FROM ecommerce_sales
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

--43. Who are the top 10 customers by revenue?
SELECT customer_id,
       customer_name,
       ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY customer_id, customer_name
ORDER BY total_revenue DESC
LIMIT 10;

--44. How much revenue comes from each customer segment?-- The ecommerce_sales dataset does not contain a gender column.-- If a customers table with gender exists:
SELECT
    segment,
    ROUND(SUM(sales), 2) AS total_revenue
FROM ecommerce_sales
GROUP BY segment
ORDER BY total_revenue DESC;

--45. How many new customers were acquired each month?
WITH first_purchase AS (
    SELECT customer_id,
           MIN(order_date) AS first_order_date
    FROM ecommerce_sales
    GROUP BY customer_id
)
SELECT EXTRACT(YEAR FROM first_order_date) AS order_year,
       EXTRACT(MONTH FROM first_order_date) AS order_month,
       COUNT(*) AS new_customers
FROM first_purchase
GROUP BY order_year, order_month
ORDER BY order_year, order_month;
