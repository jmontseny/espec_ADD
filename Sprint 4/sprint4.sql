-- Nivel 1

-- Ex 1 - Diagnóstico
SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-jordi-m.sprint3_silver.companies_clean` AS c
ON t.business_id = c.company_id
WHERE t.declined = 0
AND c.country = 'Germany'
AND DATE(t.timestamp) = '2022-03-12';


-- Ex 2 - Partitioning & Clustering

-- paso 1
CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_silver.transactions_recent` AS
SELECT
    * EXCEPT(timestamp),
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL (CAST(RAND() * 50 AS INT64)) DAY) AS timestamp
FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean`;


""" comprobación para asegurarnos que todo cae dentro de los últimos 50 días
SELECT
    MIN(DATE(timestamp)),
    MAX(DATE(timestamp))
FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_recent`; """


-- paso 2
CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY business_id
AS
SELECT * 
FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_recent`;


-- Ex 3 - Benchmark
SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_recent`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
AND declined = 0;

SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
AND declined = 0;



-- Ex 4 - Smart Caching
CREATE MATERIALIZED VIEW `sprint3-analytics-jordi-m.sprint3_gold.mv_daily_sales` AS
SELECT DATE(timestamp) AS dia, SUM(amount) AS total_ventas
FROM `sprint3-analytics-jordi-m.sprint3_gold.fact_transactions_optimized`
WHERE declined = 0
GROUP BY DATE(timestamp);


########################################################################################

-- Nivel 2
-- Ex 1 - Métricas agregadas con CTE
WITH VIP_Stats AS (
    SELECT
        user_id,
        SUM(amount) AS total_gastat,
        COUNT(*) AS num_compres,
        ROUND(AVG(amount), 2) AS tiquet_mig,
        MAX(amount) AS max_compra
    FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean`
    WHERE declined = 0
    GROUP BY user_id
    HAVING SUM(amount) > 500
)

SELECT
    u.user_id,
    CONCAT(u.name, ' ', u.surname) AS nom_complet,
    u.email,
    vip.num_compres,
    vip.tiquet_mig,
    vip.max_compra,
    vip.total_gastat
FROM VIP_Stats AS vip
JOIN `sprint3-analytics-jordi-m.sprint3_silver.users_combined` AS u
ON vip.user_id = u.user_id
ORDER BY vip.total_gastat DESC;


-- Ex 2 - Window Functions sobre vistas
WITH sales AS (
    SELECT
        dia,
        total_ventas,
        LAG(total_ventas) OVER(ORDER BY dia) AS ventas_ayer
    FROM `sprint3-analytics-jordi-m.sprint3_gold.mv_daily_sales`
)

SELECT
    *,
    ROUND(
        SAFE_DIVIDE(
            total_ventas - ventas_ayer,
            ventas_ayer
        ) * 100,
        2
    ) AS diff_percentual
FROM sales
ORDER BY dia;


-- Ex 3 - Running totals sobre vistas
SELECT
    dia,
    ROUND(total_ventas, 2) AS ventas_dia,
    ROUND(
        SUM(total_ventas) OVER (
            PARTITION BY EXTRACT(YEAR FROM dia)
            ORDER BY dia
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS ventas_acumuladas_ytd
FROM `sprint3-analytics-jordi-m.sprint3_gold.mv_daily_sales`
ORDER BY dia;


-- Ex 4 - Advanced Filtering
WITH ranked_purchases AS (
    SELECT
        user_id,
        timestamp,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY timestamp
        ) AS purchase_number
    FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean`
    WHERE declined = 0
),

third_purchase AS (
    SELECT 
        user_id,
        timestamp,
        amount
    FROM ranked_purchases
    WHERE purchase_number = 3
),

first_three_avg AS (
    SELECT
        user_id,
        ROUND(AVG(amount), 2) AS avg_first_three
    FROM ranked_purchases
    WHERE purchase_number <= 3
    GROUP BY user_id
)

SELECT
    u.user_id,
    CONCAT(u.name, ' ', u.surname) AS nom_complet,
    u.email,
    tp.timestamp AS date_third_purchase,
    tp.amount AS amount_third_purchase,
    f.avg_first_three
FROM `sprint3-analytics-jordi-m.sprint3_silver.users_combined` AS u
JOIN third_purchase AS tp
    ON u.user_id = tp.user_id
JOIN first_three_avg AS f
    ON u.user_id = f.user_id;


########################################################################################

-- Nivel 3
-- Ex 1 - Unnesting
CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_gold.dim_transactions_flat` AS

WITH exploded_transactions AS (
    SELECT
        t.transaction_id,
        t.timestamp,
        t.amount,
        product_id
    FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean` AS t
    CROSS JOIN UNNEST(t.product_ids) AS product_id
    WHERE t.declined = 0
)

SELECT
    et.transaction_id,
    et.timestamp,
    et.amount AS total_ticket,
    p.product_id AS product_sku,
    p.name AS product_name,
    p.price AS product_price
FROM exploded_transactions AS et
JOIN `sprint3-analytics-jordi-m.sprint3_silver.products_clean` AS p
    ON et.product_id = p.product_id;


SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_gold.dim_transactions_flat`;


-- Ex 2 - Simple Aggregation
SELECT product_name, COUNT(*) AS total_ventas
FROM `sprint3-analytics-jordi-m.sprint3_gold.dim_transactions_flat`
GROUP BY product_name
ORDER BY total_ventas DESC
LIMIT 5;


-- Ex 3 - Pipeline Automation and Visualisation
CREATE OR REPLACE FUNCTION
`sprint3-analytics-jordi-m.sprint3_gold.calculate_tax`
(
    amount NUMERIC,
    tax_rate NUMERIC
)
RETURNS NUMERIC
AS (
    ROUND(amount * (1 + tax_rate / 100), 2)
);



CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_gold.dim_transactions_flat` AS

WITH exploded_transactions AS (
    SELECT
        t.transaction_id,
        t.timestamp,
        t.amount,
        product_id
    FROM `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean` AS t
    CROSS JOIN UNNEST(t.product_ids) AS product_id
    WHERE t.declined = 0
)

SELECT
    et.transaction_id,
    et.timestamp,
    et.amount AS total_ticket,
    p.product_id AS product_sku,
    p.name AS product_name,
    p.price AS product_price,
    `sprint3-analytics-jordi-m.sprint3_gold.calculate_tax`(
        p.price,
        21
    ) AS product_price_tax_inc
FROM exploded_transactions AS et
JOIN `sprint3-analytics-jordi-m.sprint3_silver.products_clean` AS p
    ON et.product_id = p.product_id;
