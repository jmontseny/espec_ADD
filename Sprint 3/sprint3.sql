""" Una vez creemos el proyecto, y el primer dataset (bronze) a través de la interfaz de BigQuery,
podremos empezar a crear el segundo dataset (silver) con una consulta SQL, y el tercero a través de Cloud Shell"""

-- Creamos el dataset Silver mediante una consulta
CREATE SCHEMA IF NOT EXISTS
`sprint3-analytics-jordi-m.sprint3_silver`
OPTIONS(location='EU');


-- Creamos el dataset Gold a través de la terminal de Cloud Shell
# bq --location=EU mk -d "sprint3_gold"



# Creamos la tabla transactions_raw con delimitador ';'
CREATE EXTERNAL TABLE `sprint3-analytics-jordi-m.sprint3_bronze.transactions_raw`
(
    id STRING,
    card_id STRING,
    business_id STRING,
    timestamp STRING,
    amount STRING,
    declined STRING,
    product_ids STRING,
    user_id STRING,
    lat STRING,
    longitude STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
    field_delimiter = ';',
    skip_leading_rows = 1);


# creamos la tabla companies_raw ignorando la primera fila
CREATE EXTERNAL TABLE `sprint3-analytics-jordi-m.sprint3_bronze.companies_raw`
(
    company_id STRING,
    company_name STRING,
    phone STRING,
    email STRING,
    country STRING,
    website STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
    skip_leading_rows = 1);


CREATE EXTERNAL TABLE `sprint3-analytics-jordi-m.sprint3_bronze.american_users_raw`
(
    id STRING,
    name STRING,
    surname STRING,
    phone STRING,
    email STRING,
    birth_date STRING,
    country STRING,
    city STRING,
    postal_code STRING,
    address STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
    skip_leading_rows = 1);


CREATE EXTERNAL TABLE `sprint3-analytics-jordi-m.sprint3_bronze.european_users_raw`
(
    id STRING,
    name STRING,
    surname STRING,
    phone STRING,
    email STRING,
    birth_date STRING,
    country STRING,
    city STRING,
    postal_code STRING,
    address STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
    skip_leading_rows = 1);


CREATE EXTERNAL TABLE `sprint3-analytics-jordi-m.sprint3_bronze.credit_cards_raw`
(
    id STRING,
    user_id STRING,
    iban STRING,
    pan STRING,
    pin STRING,
    cvv STRING,
    track1 STRING,
    track2 STRING,
    expiring_date STRING
)
OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
    skip_leading_rows = 1);



-- Exercici 4: Arquitectura i Rendiment. Materialització de Dades (Assistit per IA)
-- a) prompt:
""" Write a SQL query to create a new table called transactions_raw_native in the sprint3_bronze dataset
in the project sprint3-analytics-jordi-m.
It should contain all data from the transactions_raw table in the same dataset.
Please use CREATE OR REPLACE TABLE so I don't get errors if I run it more than once. """

-- return del prompt
CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_bronze.transactions_raw_native` AS
SELECT * FROM `sprint3-analytics-jordi-m.sprint3_bronze.transactions_raw`;



-- Exercici 5: Adaptació de Sintaxi (Reporting)
-- El teu cap vol saber quins van ser els 5 dies amb més ingressos de l'any 2021.

-- si todo ha sido introducido como STRING durante la capa bronze:
SELECT 
  DATE(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp)) AS fecha,
  ROUND(SUM(SAFE_CAST(amount AS NUMERIC)), 2) AS total
FROM `sprint3-analytics-jordi-m.sprint3_bronze.transactions_raw`
WHERE SUBSTR(timestamp, 1, 4) = '2021'
AND declined = '0'
GROUP BY fecha
ORDER BY total DESC
LIMIT 5;


-- Exercici 6: Consultes Complexes
-- Necessitem un informe que creui dades.
-- Llista el nom, país i data de les transaccions realitzades per empreses
-- que van fer operacions entre 100 i 200 euros en alguna d'aquestes dates:
-- 29-04-2015, 20-07-2018 o 13-03-2024.

SELECT
    c.company_name,
    c.country,
    DATE(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp)) AS fecha,
    SAFE_CAST(t.amount AS NUMERIC) AS total
FROM `sprint3-analytics-jordi-m.sprint3_bronze.transactions_raw` AS t
JOIN `sprint3-analytics-jordi-m.sprint3_bronze.companies_raw` AS c
ON t.business_id = c.company_id
WHERE t.declined = '0'
AND SAFE_CAST(t.amount AS NUMERIC) BETWEEN 100 AND 200
AND DATE(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp)) IN ('2015-04-29', '2018-07-20', '2024-03-13');

-- FRANK's


######################################################

-- NIVEL 2
-- Exercici 1: Neteja de Productes (Data Quality)

CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_silver.products_clean` AS
SELECT
  CAST(id AS INT64) AS product_id,
  product_name AS name,
  CAST(
    TRIM(TRANSLATE(CAST(price AS STRING), '$€£¥', '')) AS NUMERIC
  ) AS price, -- NUMERIC sería mucho mejor opción para precios
  colour,
  CAST(weight AS FLOAT64) AS weight,
  SAFE_CAST(REGEXP_EXTRACT(warehouse_id, r'(\d+)') AS INT64) AS warehouse_id
FROM `sprint3-analytics-jordi-m.sprint3_bronze.products_raw`;


-- Exercici 2: Creació de Transaccions Netes (Capa Silver)

CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp) AS timestamp,
  IFNULL(SAFE_CAST(amount AS NUMERIC), 0) AS amount,
  SAFE_CAST(declined AS INT64) AS declined,
  ARRAY(
    SELECT SAFE_CAST(product_id AS INT64)
    FROM UNNEST(SPLIT(product_ids, ', ')) AS product_id
  ) AS product_ids,
  CAST(user_id AS INT64) AS user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-jordi-m.sprint3_bronze.transactions_raw`;


-- Exercici 3: Unificació d'Usuaris (UNION)
CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_silver.users_combined` AS
SELECT
  CAST(id AS INT64) AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  'Europe' AS origin,
  country,
  city,
  postal_code,
  address
FROM `sprint3-analytics-jordi-m.sprint3_bronze.european_users_raw`
UNION ALL
SELECT
  CAST(id AS INT64) AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  'America' AS origin,
  country,
  city,
  postal_code,
  address
FROM `sprint3-analytics-jordi-m.sprint3_bronze.american_users_raw`;


-- Exercici 4: Materialització de Companyies i Targetes de Crèdit
CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_silver.companies_clean` AS
SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_bronze.companies_raw`;


CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_silver.credit_cards_clean` AS
SELECT
  * EXCEPT(id, user_id),
  id AS card_id,
  CAST(user_id AS INT64) AS user_id
FROM `sprint3-analytics-jordi-m.sprint3_bronze.credit_cards_raw`;


######################################################
-- NIVEL 3
-- Exercici 1: La Vista de Màrqueting (Lògica de Negoci)
CREATE OR REPLACE VIEW `sprint3-analytics-jordi-m.sprint3_gold.v_marketing_kpis` AS
SELECT
  c.company_name,
  c.phone,
  c.country,
  ROUND(AVG(t.amount), 2) AS media_total,
  CASE
    WHEN AVG(t.amount) > 260 THEN 'Premium'
    ELSE 'Standard'
  END AS client_tier
FROM `sprint3-analytics-jordi-m.sprint3_silver.companies_clean` AS c
JOIN `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean` AS t
ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY
  c.company_id,
  c.company_name,
  c.phone,
  c.country;

-- Query para ver el resultado de la nueva vista ordenado por media_total
SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_gold.v_marketing_kpis`
ORDER BY media_total DESC;



-- Exercici 2: Rànquing de Productes (La Potència dels Arrays)

CREATE OR REPLACE TABLE `sprint3-analytics-jordi-m.sprint3_gold.product_sales_ranking` AS
SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  COUNT(t.product_ids) AS total_sold

FROM `sprint3-analytics-jordi-m.sprint3_silver.products_clean` AS p
LEFT JOIN `sprint3-analytics-jordi-m.sprint3_silver.transactions_clean` AS t
    ON p.product_id IN UNNEST(t.product_ids)
  AND t.declined = 0
GROUP BY p.product_id, p.name, p.price, p.colour
ORDER BY total_sold DESC;


-- Query para ver el resultado de la nueva tabla
SELECT *
FROM `sprint3-analytics-jordi-m.sprint3_gold.product_sales_ranking`;

-- Exercici 3: Exportació de Resultats
