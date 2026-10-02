-- Food Delivery Operations & Delivery Performance Analytics
-- SQL Server project script
-- Dataset: 50,000 cleaned food-delivery orders

CREATE DATABASE FoodDeliveryAnalytics;
GO
USE FoodDeliveryAnalytics;
GO

CREATE TABLE food_delivery_orders (
    [order_id] VARCHAR(100),
    [customer_id] VARCHAR(100),
    [restaurant_id] VARCHAR(100),
    [driver_id] VARCHAR(100),
    [order_timestamp] DATETIME2,
    [order_date] DATE,
    [order_hour] INT,
    [day_of_week] VARCHAR(100),
    [is_weekend] INT,
    [customer_age] INT,
    [customer_type] VARCHAR(100),
    [restaurant_type] VARCHAR(100),
    [restaurant_primary_category] VARCHAR(100),
    [restaurant_rating] DECIMAL(10,2),
    [items_count] INT,
    [subtotal] DECIMAL(10,2),
    [discount_percent] INT,
    [tax_amount] DECIMAL(10,2),
    [service_fee] DECIMAL(10,2),
    [delivery_fee] DECIMAL(10,2),
    [order_total] DECIMAL(10,2),
    [payment_method] VARCHAR(100),
    [tip_amount] DECIMAL(10,2),
    [distance_km] DECIMAL(10,2),
    [weather] VARCHAR(100),
    [traffic_level] VARCHAR(100),
    [delivery_partner_experience_months] INT,
    [delivery_partner_rating] DECIMAL(10,2),
    [restaurant_preparation_time_minutes] DECIMAL(10,2),
    [estimated_delivery_time_minutes] DECIMAL(10,2),
    [actual_delivery_time_minutes] DECIMAL(10,2),
    [late_delivery] INT,
    [order_status] INT,
    [cancellation_reason] VARCHAR(100),
    [customer_rating] DECIMAL(10,2),
    [city] VARCHAR(100),
    [delivery_area] VARCHAR(100),
    [city_original] VARCHAR(100),
    [delivery_area_original] VARCHAR(100)
);
GO

-- After importing the CSV into the table, run the analysis below.

-- 1. Total orders
SELECT COUNT(*) AS total_orders FROM food_delivery_orders;
GO

-- 2. Completed vs cancelled orders
SELECT order_status, COUNT(*) AS orders,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percentage
FROM food_delivery_orders
GROUP BY order_status
ORDER BY orders DESC;
GO

-- 3. Overall revenue from completed orders
SELECT
    SUM(order_total) AS completed_revenue,
    AVG(order_total) AS average_order_value
FROM food_delivery_orders
WHERE order_status = 'Completed';
GO

-- 4. Cancellation rate
SELECT
    COUNT(CASE WHEN order_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*) AS cancellation_rate
FROM food_delivery_orders;
GO

-- 5. Late delivery rate
SELECT
    COUNT(CASE WHEN late_delivery = 1 THEN 1 END) * 100.0 / COUNT(*) AS late_delivery_rate
FROM food_delivery_orders
WHERE order_status = 'Completed';
GO

-- 6. City performance
SELECT
    city,
    COUNT(*) AS orders,
    SUM(CASE WHEN order_status='Completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    CAST(SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS cancellation_rate,
    SUM(CASE WHEN order_status='Completed' THEN order_total ELSE 0 END) AS revenue,
    AVG(CASE WHEN order_status='Completed' THEN order_total END) AS avg_order_value
FROM food_delivery_orders
GROUP BY city
ORDER BY orders DESC;
GO

-- 7. Delivery performance by traffic
SELECT
    traffic_level,
    COUNT(*) AS completed_orders,
    AVG(actual_delivery_time_minutes) AS avg_actual_delivery_time,
    AVG(estimated_delivery_time_minutes) AS avg_estimated_delivery_time,
    AVG(CAST(late_delivery AS DECIMAL(10,2))) * 100 AS late_delivery_rate,
    AVG(distance_km) AS avg_distance_km
FROM food_delivery_orders
WHERE order_status='Completed'
GROUP BY traffic_level
ORDER BY avg_actual_delivery_time DESC;
GO

-- 8. Peak order hours
SELECT
    order_hour,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status='Completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN order_status='Completed' THEN order_total ELSE 0 END) AS revenue
FROM food_delivery_orders
GROUP BY order_hour
ORDER BY total_orders DESC;
GO

-- 9. Day-of-week performance
SELECT
    day_of_week,
    COUNT(*) AS orders,
    SUM(CASE WHEN order_status='Completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN order_status='Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN order_status='Completed' THEN order_total ELSE 0 END) AS revenue
FROM food_delivery_orders
GROUP BY day_of_week
ORDER BY orders DESC;
GO

-- 10. Weather impact on delivery
SELECT
    weather,
    COUNT(*) AS completed_orders,
    AVG(actual_delivery_time_minutes) AS avg_delivery_time,
    AVG(CAST(late_delivery AS DECIMAL(10,2))) * 100 AS late_delivery_rate
FROM food_delivery_orders
WHERE order_status='Completed'
GROUP BY weather
ORDER BY late_delivery_rate DESC;
GO

-- 11. Delivery area performance
SELECT
    city,
    delivery_area,
    COUNT(*) AS orders,
    AVG(CASE WHEN order_status='Completed' THEN actual_delivery_time_minutes END) AS avg_delivery_time,
    AVG(CASE WHEN order_status='Completed' THEN CAST(late_delivery AS DECIMAL(10,2)) END) * 100 AS late_delivery_rate
FROM food_delivery_orders
GROUP BY city, delivery_area
ORDER BY late_delivery_rate DESC;
GO

-- 12. Restaurant category performance
SELECT
    restaurant_primary_category,
    COUNT(*) AS orders,
    AVG(CASE WHEN order_status='Completed' THEN order_total END) AS avg_order_value,
    AVG(CASE WHEN order_status='Completed' THEN restaurant_preparation_time_minutes END) AS avg_prep_time,
    AVG(CASE WHEN order_status='Completed' THEN customer_rating END) AS avg_customer_rating
FROM food_delivery_orders
GROUP BY restaurant_primary_category
ORDER BY orders DESC;
GO

-- 13. Driver experience vs delivery performance
SELECT
    CASE
        WHEN delivery_partner_experience_months < 12 THEN '0-11 months'
        WHEN delivery_partner_experience_months < 24 THEN '12-23 months'
        WHEN delivery_partner_experience_months < 36 THEN '24-35 months'
        ELSE '36+ months'
    END AS experience_group,
    COUNT(*) AS completed_orders,
    AVG(actual_delivery_time_minutes) AS avg_delivery_time,
    AVG(CAST(late_delivery AS DECIMAL(10,2))) * 100 AS late_delivery_rate,
    AVG(delivery_partner_rating) AS avg_driver_rating
FROM food_delivery_orders
WHERE order_status='Completed'
GROUP BY CASE
        WHEN delivery_partner_experience_months < 12 THEN '0-11 months'
        WHEN delivery_partner_experience_months < 24 THEN '12-23 months'
        WHEN delivery_partner_experience_months < 36 THEN '24-35 months'
        ELSE '36+ months'
    END
ORDER BY avg_delivery_time;
GO

-- 14. Top 10 restaurants by completed revenue
SELECT TOP 10
    restaurant_id,
    COUNT(*) AS completed_orders,
    SUM(order_total) AS revenue,
    AVG(order_total) AS avg_order_value
FROM food_delivery_orders
WHERE order_status='Completed'
GROUP BY restaurant_id
ORDER BY revenue DESC;
GO

-- 15. Cancellation reasons
SELECT
    cancellation_reason,
    COUNT(*) AS cancelled_orders,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS percentage
FROM food_delivery_orders
WHERE order_status='Cancelled'
GROUP BY cancellation_reason
ORDER BY cancelled_orders DESC;
GO

-- 16. Customer type performance
SELECT
    customer_type,
    COUNT(*) AS orders,
    AVG(CASE WHEN order_status='Completed' THEN order_total END) AS avg_order_value,
    AVG(CASE WHEN order_status='Completed' THEN customer_rating END) AS avg_customer_rating,
    AVG(CASE WHEN order_status='Completed' THEN CAST(late_delivery AS DECIMAL(10,2)) END) * 100 AS late_delivery_rate
FROM food_delivery_orders
GROUP BY customer_type
ORDER BY orders DESC;
GO

-- 17. Weekend vs weekday
SELECT
    CASE WHEN is_weekend=1 THEN 'Weekend' ELSE 'Weekday' END AS period_type,
    COUNT(*) AS orders,
    SUM(CASE WHEN order_status='Completed' THEN order_total ELSE 0 END) AS revenue,
    AVG(CASE WHEN order_status='Completed' THEN order_total END) AS avg_order_value,
    AVG(CASE WHEN order_status='Completed' THEN CAST(late_delivery AS DECIMAL(10,2)) END) * 100 AS late_delivery_rate
FROM food_delivery_orders
GROUP BY is_weekend
ORDER BY is_weekend DESC;
GO

-- 18. Delivery time gap: actual vs estimated
SELECT
    AVG(actual_delivery_time_minutes - estimated_delivery_time_minutes) AS avg_time_gap,
    AVG(CASE WHEN actual_delivery_time_minutes > estimated_delivery_time_minutes
             THEN actual_delivery_time_minutes - estimated_delivery_time_minutes ELSE 0 END) AS avg_delay_minutes_for_late_orders
FROM food_delivery_orders
WHERE order_status='Completed';
GO

-- 19. Data quality duplicate check
SELECT order_id, COUNT(*) AS duplicate_count
FROM food_delivery_orders
GROUP BY order_id
HAVING COUNT(*) > 1;
GO

-- 20. Data quality null check
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_order_status
FROM food_delivery_orders;
GO
