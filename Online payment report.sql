-- ONLINE PAYMENT APP ANALYSIS -- 

-- Join table payment 2017 and payment 2018 -- 

WITH table_union AS (
    SELECT * FROM payment_history_17
    UNION 
    SELECT * FROM payment_history_18 
)
SELECT * 
INTO #payment_history 
FROM table_union

-- OVERVIEW --
-- Total Customers -- 

SELECT 
     YEAR(transaction_date) AS [Year],
     COUNT( DISTINCT customer_id) AS total_customers
FROM 
     #payment_history 
GROUP BY 
     YEAR(transaction_date);

-- Total Transactions -- 

SELECT 
     YEAR(transaction_date) AS [Year],
     COUNT(order_id) AS total_transactions
FROM 
     #payment_history 
GROUP BY 
     YEAR(transaction_date);

-- TRANSACTION AND AMOUNT TRENDS --
-- By Month and Year -- 

SELECT 
    YEAR(transaction_date) AS [Year],
    MONTH(transaction_date) AS [Month],
    COUNT(order_id) AS total_transactions,
    SUM(CAST(final_price AS BIGINT)) AS total_money 
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
WHERE 
    mess.description = 'Success'
GROUP BY 
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY 
    [Year], [Month]

-- By Hour -- 

SELECT 
     DATEPART(HOUR, transaction_date) AS [Hour],
     COUNT(order_id) AS total_transactions
FROM 
     #payment_history AS his
JOIN 
     table_message AS mess 
     ON his.message_id = mess.message_id 
WHERE 
     mess.description = 'Success'
GROUP BY 
     DATEPART(HOUR, transaction_date)
ORDER BY 
     [Hour]

-- SUCCESS RATE -- 
-- Success & Failed transactions by Year -- 

SELECT 
    YEAR(transaction_date) AS [Year],
    IIF(mess.description = 'Success', 'Success', 'Unsuccess') AS success_status, 
    COUNT(order_id) AS total_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
GROUP BY 
    YEAR(transaction_date),
    IIF(mess.description = 'Success', 'Success', 'Unsuccess')
ORDER BY 
    [Year]

-- Transaction trends by Hour -- 

SELECT 
    DATEPART(HOUR, transaction_date) AS [Hour],
    COUNT(order_id) AS total_transactions,
    COUNT(CASE WHEN mess.description = 'Success' THEN order_id END) AS success_transactions,
    COUNT(CASE WHEN mess.description <> 'Success' THEN order_id END) AS failed_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
GROUP BY 
    DATEPART(HOUR, transaction_date)
ORDER BY 
    [Hour]

-- Unsucces transactions by Month -- 

SELECT 
    YEAR(transaction_date) AS [Year],
    MONTH(transaction_date) AS [Month],
    COUNT(order_id) AS failed_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
WHERE 
    mess.description <> 'Success'
GROUP BY 
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY 
    [Year], [Month]

-- Error types -- 

SELECT 
    mess.description AS Error_types,
    COUNT(order_id) AS failed_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
WHERE 
    mess.description <> 'Success'
GROUP BY 
    mess.description 
ORDER BY failed_transactions DESC 

-- Top 3 error types trend --

WITH table_rank AS (
    SELECT 
        YEAR(his.transaction_date) AS [Year],
        MONTH(his.transaction_date) AS [Month],
        mess.description AS Error_types,
        COUNT(his.order_id) AS failed_transactions,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(his.transaction_date), MONTH(his.transaction_date)
            ORDER BY COUNT(his.order_id) DESC
        ) AS row_num
    FROM 
        #payment_history AS his
    JOIN 
        table_message AS mess 
        ON his.message_id = mess.message_id 
    WHERE 
        mess.description <> 'Success'
    GROUP BY 
        YEAR(his.transaction_date),
        MONTH(his.transaction_date),
        mess.description
)
SELECT *
FROM table_rank 
WHERE row_num BETWEEN 1 AND 3 

-- PAYING METHOD --
-- Success & Failed transactions by Method -- 

SELECT 
    method.name AS methods,
    COUNT(CASE WHEN mess.description = 'Success' THEN order_id END) AS success_transactions,
    COUNT(CASE WHEN mess.description <> 'Success' THEN order_id END) AS failed_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    paying_method AS method 
    ON his.payment_id = method.method_id
GROUP BY 
    method.name; 

-- Total money by Method -- 

SELECT 
    method.name AS methods,
    SUM(CAST(final_price AS BIGINT)) AS total_money
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    paying_method AS method 
    ON his.payment_id = method.method_id
WHERE 
    mess.description = 'Success'
GROUP BY 
    method.name 
ORDER BY total_money DESC 

-- Method trends -- 

SELECT 
    YEAR(transaction_date) AS [Year],
    MONTH(transaction_date) AS [Month],
    method.name AS methods, 
    COUNT(order_id) AS total_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    paying_method AS method 
    ON his.payment_id = method.method_id
WHERE 
    mess.description = 'Success'
GROUP BY 
    YEAR(transaction_date),
    MONTH(transaction_date),
    method.name 
ORDER BY 
    [Year], [Month]

-- Error types by Methods -- 

SELECT 
    method.name AS methods, 
    mess.description AS Error_types,
    COUNT(order_id) AS total_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    paying_method AS method 
    ON his.payment_id = method.method_id
WHERE 
    mess.description <> 'Success'
GROUP BY 
    method.name, 
    mess.description
ORDER BY 
    methods, total_transactions DESC 

-- PRODUCTS & PROMOTION -- 
-- Transaction & Total Money by Product Groups -- 

SELECT 
    product_group,
    COUNT(order_id) AS total_transactions,
    SUM(CAST(final_price AS BIGINT)) AS total_money
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    product
    ON his.product_id = product.product_number
WHERE 
    mess.description = 'Success'
GROUP BY 
    product_group
ORDER BY total_transactions DESC 

-- Transaction & Money trends by Product Groups -- 

SELECT 
    YEAR(transaction_date) AS [Year],
    MONTH(transaction_date) AS [Month],
    product_group, 
    COUNT(order_id) AS total_transactions,
    SUM(CAST(final_price AS BIGINT)) AS total_money
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    product
    ON his.product_id = product.product_number
WHERE 
    mess.description = 'Success'
GROUP BY 
    YEAR(transaction_date),
    MONTH(transaction_date),
    product_group  
ORDER BY 
    [Year], [Month], total_transactions DESC  

-- Money transaction trends by Product Groups -- 

SELECT 
    YEAR(transaction_date) AS [Year],
    MONTH(transaction_date) AS [Month],
    product_group, 
    SUM(CAST(final_price AS BIGINT)) AS total_money
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    product
    ON his.product_id = product.product_number
WHERE 
    mess.description = 'Success'
GROUP BY 
    YEAR(transaction_date),
    MONTH(transaction_date),
    product_group  
ORDER BY 
    [Year], [Month], total_money DESC 

-- Methods by Product Group -- 

SELECT 
    product_group, 
    method.name AS methods,
    COUNT(order_id) AS total_transactions,
    SUM(CAST(final_price AS BIGINT)) AS total_money
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    product
    ON his.product_id = product.product_number
JOIN 
    paying_method AS method
    ON his.payment_id = method.method_id
WHERE 
    mess.description = 'Success'
GROUP BY 
    product_group,
    method.name  
ORDER BY 
    product_group, total_transactions DESC, total_money DESC 

-- Promotion orders --

SELECT 
    IIF(discount_price > 0, 'Promotion', 'Non-promotion') AS promo_status, 
    COUNT(order_id) AS total_transactions,
    FORMAT(
        CAST(COUNT(order_id) AS DECIMAL(10, 2)) / 
        (SELECT COUNT(*) 
         FROM #payment_history 
         WHERE message_id = '1'), 
        'p'
    ) AS promo_pct
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
WHERE 
    mess.description = 'Success'
GROUP BY 
    IIF(discount_price > 0, 'Promotion', 'Non-promotion');
    
-- Promo order trends

SELECT 
    YEAR(transaction_date) AS [Year],
    MONTH(transaction_date) AS [Month],
    COUNT(order_id) AS promo_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
WHERE 
    mess.description = 'Success'
    AND 
    discount_price > 0 
GROUP BY 
    YEAR(transaction_date),
    MONTH(transaction_date)
ORDER BY 
    [Year], [Month] 

-- Promotion participation rate -- 

WITH table_promo AS (
    SELECT 
        YEAR(transaction_date) AS [Year],
        MONTH(transaction_date) AS [Month],
        COUNT(order_id) AS total_transactions,
        COUNT(CASE WHEN discount_price > 0 THEN order_id END) AS promo_transactions
    FROM 
        #payment_history AS his
    JOIN 
        table_message AS mess 
        ON his.message_id = mess.message_id 
    WHERE 
        mess.description = 'Success'
    GROUP BY 
        YEAR(transaction_date),
        MONTH(transaction_date)
)
SELECT table_promo.*,
       FORMAT(CAST(promo_transactions AS DECIMAL) / total_transactions, 'p') AS promo_pct 
FROM table_promo
ORDER BY 
       [Year], [Month]

-- Which products are eligible for promotion? -- 

SELECT 
    product_group, 
    IIF(discount_price > 0, 'Promotion', 'Non - promotion') AS promo_status,
    COUNT(order_id) AS promo_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    product 
    ON his.product_id = product.product_number
WHERE 
    mess.description = 'Success'
GROUP BY 
    product_group,
    IIF(discount_price > 0, 'Promotion', 'Non - promotion')
ORDER BY 
    product_group 

-- Promotional orders by Category -- 

SELECT 
    category, 
    COUNT(order_id) AS promo_transactions
FROM 
    #payment_history AS his
JOIN 
    table_message AS mess 
    ON his.message_id = mess.message_id 
JOIN 
    product 
    ON his.product_id = product.product_number
WHERE 
    mess.description = 'Success'
    AND 
    discount_price > 0 
    AND 
    product_group = 'Payment'
GROUP BY 
    category
ORDER BY 
    promo_transactions DESC  

-- Retention rates in 2017 -- 

WITH table_full AS (
    SELECT 
        customer_id,
        transaction_date,
        MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM 
        payment_history_17 AS his_17 
    JOIN 
        table_message AS mess 
        ON his_17.message_id = mess.message_id 
    WHERE 
        mess.description = 'Success'
),
table_retained AS (
    SELECT 
        first_month,
        MONTH(transaction_date) - first_month AS month_n,
        COUNT(DISTINCT customer_id) AS retained_customers  
    FROM 
        table_full
    GROUP BY
        first_month,
        MONTH(transaction_date) - first_month 
),
table_original AS (
    SELECT 
        table_retained.*,
        MAX(retained_customers) OVER (PARTITION BY first_month) AS original_customers
    FROM 
        table_retained 
)
, table_retention AS (      
SELECT 
    table_original.*,
    CAST(retained_customers AS DECIMAL) / original_customers AS pct
FROM 
    table_original
)
SELECT 
    first_month, 
    original_customers,
    [0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]
FROM (
    SELECT 
        first_month, 
        month_n, 
        original_customers, 
        CAST(pct AS DECIMAL(10, 2)) AS pct
    FROM 
        table_retention 
) AS source_table 
PIVOT (
    SUM(pct)
    FOR month_n IN ([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11])
) AS pivot_logic
ORDER BY first_month;

-- Retention rates in 2018 -- 

WITH table_full AS (
    SELECT 
        customer_id,
        transaction_date,
        MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM 
        payment_history_18 AS his_18 
    JOIN 
        table_message AS mess 
        ON his_18.message_id = mess.message_id 
    WHERE 
        mess.description = 'Success'
),
table_retained AS (
    SELECT 
        first_month,
        MONTH(transaction_date) - first_month AS month_n,
        COUNT(DISTINCT customer_id) AS retained_customers  
    FROM 
        table_full
    GROUP BY
        first_month,
        MONTH(transaction_date) - first_month 
),
table_original AS (
    SELECT 
        table_retained.*,
        MAX(retained_customers) OVER (PARTITION BY first_month) AS original_customers
    FROM 
        table_retained 
)
, table_retention AS (      
SELECT 
    table_original.*,
    CAST(retained_customers AS DECIMAL) / original_customers AS pct
FROM 
    table_original
)
SELECT 
    first_month, 
    original_customers,
    [0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]
FROM (
    SELECT 
        first_month, 
        month_n, 
        original_customers, 
        CAST(pct AS DECIMAL(10, 2)) AS pct
    FROM 
        table_retention 
) AS source_table 
PIVOT (
    SUM(pct)
    FOR month_n IN ([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11])
) AS pivot_logic
ORDER BY first_month;

-- Retention rates for non - promotion customers in 2018 -- 

WITH table_full AS (
    SELECT 
        customer_id,
        transaction_date,
        MIN(MONTH(transaction_date)) OVER (PARTITION BY customer_id) AS first_month
    FROM 
        payment_history_18 AS his_18 
    JOIN 
        table_message AS mess 
        ON his_18.message_id = mess.message_id 
    WHERE 
        mess.description = 'Success'
        AND 
        discount_price = 0
),
table_retained AS (
    SELECT 
        first_month,
        MONTH(transaction_date) - first_month AS month_n,
        COUNT(DISTINCT customer_id) AS retained_customers  
    FROM 
        table_full
    GROUP BY
        first_month,
        MONTH(transaction_date) - first_month 
),
table_original AS (
    SELECT 
        table_retained.*,
        MAX(retained_customers) OVER (PARTITION BY first_month) AS original_customers
    FROM 
        table_retained 
)
, table_retention AS (      
SELECT 
    table_original.*,
    CAST(retained_customers AS DECIMAL) / original_customers AS pct
FROM 
    table_original
)
SELECT 
    first_month, 
    original_customers,
    [0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]
FROM (
    SELECT 
        first_month, 
        month_n, 
        original_customers, 
        CAST(pct AS DECIMAL(10, 2)) AS pct
    FROM 
        table_retention 
) AS source_table 
PIVOT (
    SUM(pct)
    FOR month_n IN ([0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11])
) AS pivot_logic
ORDER BY first_month;