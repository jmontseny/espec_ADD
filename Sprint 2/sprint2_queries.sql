# para crear y poblar la BBDD, abrimos y ejecutamos los archivos:
# N1-Ex.1__ estructura dades y N1-Ex.1__dades_introduir

USE transactions;

-- Nivell 1
-- Exercici 2
# Utilitzant JOIN realitzaràs les següents consultes:
# Llistat dels països que estan generant vendes.

SELECT DISTINCT c.country
FROM transaction AS t
JOIN company AS c
ON t.company_id = c.id
WHERE t.declined = 0;


# Des de quants països es generen les vendes.

SELECT COUNT(DISTINCT c.country) AS total_paises
FROM transaction AS t
JOIN company AS c
ON t.company_id = c.id
WHERE t.declined = 0;


# Identifica la companyia amb la mitjana més gran de vendes.

SELECT c.company_name, ROUND(AVG(t.amount), 2) AS media_ventas
FROM transaction AS t
JOIN company AS c
ON t.company_id = c.id
WHERE t.declined = 0
GROUP BY t.company_id
ORDER BY media_ventas DESC
LIMIT 1;


""" Exercici 3
# Utilitzant només subconsultes (sense utilitzar JOIN):
# Mostra totes les transaccions realitzades per empreses d'Alemanya. """

SELECT *
FROM transaction AS t
WHERE declined = 0
AND EXISTS (
	SELECT 1
	FROM company AS c
	WHERE c.id = t.company_id
	AND c.country = "Germany"
);


# Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.

SELECT (
	SELECT company_name
    FROM company
    WHERE id = transaction.company_id
    ) AS nombre_compania,
    ROUND(AVG(amount), 2) AS media_empresa
FROM transaction
WHERE declined = 0
GROUP BY company_id
HAVING media_empresa > (
	SELECT AVG(amount)
	FROM transaction
    WHERE declined = 0)
ORDER BY media_empresa DESC;


""" Eliminaran del sistema les empreses que no tenen transaccions registrades,
entrega el llistat d'aquestes empreses. """

SELECT *
FROM company AS c
WHERE NOT EXISTS (
	SELECT t.company_id
	FROM transaction AS t
	WHERE t.company_id = c.id
);


""" Exercici 4
La teva tasca és dissenyar i crear una taula anomenada "credit_card"
que emmagatzemi detalls crucials sobre les targetes de crèdit.
La nova taula ha de ser capaç d'identificar de manera única cada targeta
i establir una relació adequada amb les altres dues taules ("transaction" i "company").
Després de crear la taula serà necessari que ingressis la informació del document denominat "dades_introduir_credit".
Recorda mostrar el diagrama i realitzar una breu descripció d'aquest. """

CREATE TABLE IF NOT EXISTS credit_card (
	id VARCHAR(15) PRIMARY KEY,
	iban VARCHAR(34) UNIQUE,
	# IBAN (which can be up to 34 alphanumeric characters)
	pan VARCHAR(19) UNIQUE,
	# PAN stands for Primary Account Number.
	# It is the technical term for the 14- to 19-digit number
	pin VARCHAR(6), # can be up to 6 digits in some countries
	cvv VARCHAR(4), # can be up to 4 digits in some countries
	expiring_date VARCHAR(10)
);

# introducimos los datos de N1-Ex.4__ datos_introducir_credit

ALTER TABLE transaction
ADD CONSTRAINT fk_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);


""" Exercici 5
El departament de Recursos Humans ha identificat un error
en el número de compte associat a la targeta de crèdit amb ID CcU-2938.
La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999.
Recorda mostrar que el canvi es va realitzar. """

SELECT *
FROM credit_card
WHERE id = "CcU-2938";

IF EXISTS (
	SELECT *
	FROM credit_card
	WHERE id = "CcU-2938")
THEN
	UPDATE credit_card
	SET iban = "TR323456312213576817699999"
	WHERE id = "CcU-2938"
END IF;

""" O...

INSERT INTO credit_card (id, iban)
VALUES ('CcU-2938', 'TR323456312213576817699999')
ON DUPLICATE KEY UPDATE
iban = 'TR323456312213576817699999'; 
# si existe, actualiza
# si no existe, inserta """

SELECT *
FROM credit_card
WHERE id = "CcU-2938";


-- Exercici 6
# En la taula "transaction" ingressa una nova transacció amb la següent informació:

SELECT * FROM company WHERE id = 'b-9999';
INSERT INTO company (id) VALUES ('b-9999');

INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) 
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', '9999', '829.999', '-117.999', '111.11', '0');

SELECT * FROM transaction WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


-- Exercici 7
# Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi realitzat.

ALTER TABLE credit_card
DROP COLUMN pan;

SELECT *
FROM credit_card;


""" Exercici 8
# Descarrega els arxius CSV que trobaràs a l'apartat de recursos:
# Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui,
# almenys 4 taules de les quals puguis realitzar les següents consultes: """

""" La taula de products.csv l'utilitzarem més endavant. """

-- Eliminamos la BBDD si existe y la creamos si no existe
DROP DATABASE IF EXISTS transactions_db;
CREATE DATABASE IF NOT EXISTS transactions_db;
USE transactions_db;

    -- Creamos la tabla companies
CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR(10) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(20),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255),
    merchant_category VARCHAR(25),
    merchant_price_position VARCHAR(25)
);

    -- Creamos la tabla credit_cards
CREATE TABLE IF NOT EXISTS credit_cards (
	id VARCHAR(20) PRIMARY KEY,
    user_id VARCHAR(15),
	iban VARCHAR(34) UNIQUE,
	# IBAN (which can be up to 34 alphanumeric characters)
	pan VARCHAR(19), # PAN stands for Primary Account Number.
	# It is the technical term for the 14- to 19-digit number
	pin VARCHAR(6), # can be up to 6 digits in some countries
	cvv VARCHAR(4), # can be up to 4 digits in some countries
    track1 VARCHAR(100),
    track2 VARCHAR(100),
	expiring_date DATE,
    card_type VARCHAR(25),
    card_renewal_flag BOOLEAN
);

    -- Creamos la tabla users donde juntaremos EU y USA_users
CREATE TABLE IF NOT EXISTS users (
	id INT UNSIGNED PRIMARY KEY,
    name VARCHAR(50),
	surname VARCHAR(100),
    phone VARCHAR(25),
    email VARCHAR(200),
    birth_date DATE,
	continent VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(15),
    address VARCHAR(200),
    signup_date DATE,
    user_segment VARCHAR(35),
    income_band VARCHAR(25)
);

    -- Creamos la tabla transaction
CREATE TABLE IF NOT EXISTS transactions (
	id VARCHAR(150) PRIMARY KEY,
	card_id VARCHAR(20),
	business_id VARCHAR(10),
	timestamp TIMESTAMP,
	amount DECIMAL(10, 2),
	declined BOOLEAN,
	product_ids VARCHAR(50),
	user_id INT UNSIGNED,
	lat FLOAT,
	longitude FLOAT,
	discount_amount DECIMAL(10, 2),
	tax_amount DECIMAL(10, 2),
	shipping_amount DECIMAL(10, 2),
	channel VARCHAR(25),
	campaign_id VARCHAR(25),
	device_type VARCHAR(20),
	is_international BOOLEAN,
	decline_reason VARCHAR(100),
	distance_km FLOAT,
	FOREIGN KEY (card_id) REFERENCES credit_cards(id),
	FOREIGN KEY (business_id) REFERENCES companies(company_id),
	FOREIGN KEY (user_id) REFERENCES users(id)
);

# cargamos CSVs

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(company_id, company_name, phone, email, country, website, merchant_category, merchant_price_position);

# previsualizamos la tabla 
# SELECT * FROM companies;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(id, user_id, iban, pan, pin, cvv, track1, track2, @expiring_date, card_type, card_renewal_flag)

SET expiring_date = STR_TO_DATE(@expiring_date, '%m/%d/%y');

# previsualizamos la tabla 
# SELECT * FROM credit_cards;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__european_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(id, name, surname, phone, email, @birth_date, country, city, postal_code, address, signup_date, user_segment, income_band)

SET birth_date = STR_TO_DATE(@birth_date, '%b %d, %Y'),
	continent = 'Europe';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__american_users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(id, name, surname, phone, email, @birth_date, country, city, postal_code, address, signup_date, user_segment, income_band)

SET birth_date = STR_TO_DATE(@birth_date, '%b %d, %Y'),
	continent = 'America';

# previsualizamos la tabla 
# SELECT * FROM users;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude, discount_amount, tax_amount,
	shipping_amount, channel, campaign_id, device_type, is_international, decline_reason, distance_km);
    
# previsualizamos la tabla 
# SELECT * FROM transactions;

# check que las uniones funcionan bien
SELECT *
FROM transactions t
JOIN companies c
ON t.business_id = c.company_id;


""" Exercici 9
Realitza una subconsulta que mostri tots els usuaris
amb més de 80 transaccions utilitzant almenys 2 taules. """

SELECT (
	SELECT name
    FROM users AS u
    WHERE u.id = t.user_id
    ) AS nombre,
    COUNT(*) AS total_transacciones 
FROM transactions AS t
GROUP BY t.user_id
HAVING total_transacciones > 80;


""" Exercici 10
Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd,
utilitza almenys 2 taules. """

SELECT cc.iban, ROUND(AVG(t.amount), 2) AS media_gasto
FROM transactions AS t
JOIN companies AS c
ON t.business_id = c.company_id
JOIN credit_cards AS cc
ON t.card_id = cc.id
WHERE c.company_name = "Donec Ltd"
AND cc.card_type = "credit"
AND t.declined = 0
GROUP BY cc.iban
ORDER BY media_gasto DESC;


######################################################################

-- Nivell 2
-- Exercici 1
# Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes.
# Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(timestamp) AS dia, SUM(amount) AS total
FROM transactions
WHERE declined = 0
GROUP BY dia
ORDER BY total DESC
LIMIT 5;


""" Exercici 2
# Presenta el nom, telèfon, país, data i amount, 
# d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros
# i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024.
# Ordena els resultats de major a menor quantitat. """

SELECT c.company_name, c.phone, c.country, DATE(t.timestamp) AS dia, t.amount
FROM transactions AS t
JOIN companies AS c
ON t.business_id = c.company_id
WHERE t.declined = 0
AND DATE(t.timestamp) IN ("2015-04-29", "2018-07-20", "2024-03-13")
AND t.amount BETWEEN 350 AND 400
ORDER BY t.amount DESC;


""" Exercici 3
# Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi,
# per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses,
# però el departament de recursos humans és exigent i
# vol un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys. """

SELECT c.company_name, 
	CASE
		WHEN COUNT(*) >= 400 THEN 'igual o más de 400 transacciones'
        ELSE 'menos de 400 transacciones'
	END AS total_transacciones
FROM transactions AS t
JOIN companies AS c
ON t.business_id = c.company_id
WHERE t.declined = 0
GROUP BY c.company_name;


-- Exercici 4
# Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

# previsualizamos el objetivo a eliminar
SELECT *
FROM transactions
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

DELETE FROM transactions
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

SELECT *
FROM transactions
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";


""" Exercici 5
# La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives.
# S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions.
# Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació:
# Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia.
# Presenta la vista creada, ordenant les dades de major a menor mitjana de compra. """

CREATE VIEW VistaMarketing AS
SELECT c.company_name, c.phone, c.country, ROUND(AVG(t.amount), 2) AS media_transacciones
FROM transactions AS t
JOIN companies AS c
ON t.business_id = c.company_id
WHERE t.declined = 0
GROUP BY t.business_id;

SELECT *
FROM VistaMarketing
ORDER BY media_transacciones DESC;


######################################################################

-- Nivell 3
""" Exercici 1
# Crea una nova taula que reflecteixi l'estat de les targetes de crèdit
# basat en si les tres últimes transaccions han estat declinades aleshores és inactiu,
# si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon: """

CREATE TABLE credit_card_status AS
WITH ultimas_transacciones AS (
	SELECT t.card_id, t.timestamp, t.declined,
		ROW_NUMBER() OVER(PARTITION BY t.card_id ORDER BY t.timestamp DESC) AS numero_fila_id
	FROM transactions AS t
	JOIN credit_cards AS c
	ON t.card_id = c.id
	WHERE c.card_type = "credit"
)
SELECT card_id,
CASE
	WHEN SUM(declined) = 3 THEN 1
    ELSE 0
END AS inactive
FROM ultimas_transacciones
WHERE numero_fila_id <= 3
GROUP BY card_id;

# 👉 Quantes targetes estan actives?
SELECT COUNT(*) AS total_tarjetas_activas
FROM credit_card_status
WHERE inactive = 0;


""" Exercici 2
# Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv
# amb la base de dades creada (ja que fins ara no podíem fer-ho),
# tenint en compte que des de transaction tens product_ids. Genera la següent consulta: """

CREATE TABLE IF NOT EXISTS products (
	id INT UNSIGNED PRIMARY KEY,
	product_name VARCHAR(100),
	price DECIMAL(10,2),
	colour VARCHAR(12),
	weight DECIMAL(5,2),
	warehouse_id VARCHAR(10),
	category VARCHAR(20),
	brand VARCHAR(50),
	cost  DECIMAL(10,2),
	launch_date DATE
);

# cargamos la data del csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/N1-Ex.8__products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(id, product_name, @price, colour, weight, warehouse_id, category, brand, @cost, launch_date)

SET price = REPLACE(@price, '$', ''),
	cost = REPLACE(@cost, '$', '');

SELECT * FROM products;

# solucion con función FIND_IN_SET()
""" 👉 Necessitem conèixer el nombre de vegades que s'ha venut cada producte. """

SELECT p.id, COUNT(*) AS total
FROM transactions AS t
JOIN products AS p
ON FIND_IN_SET(p.id, REPLACE(t.product_ids, ', ', ',')) > 0
GROUP BY p.id;


# solución más compleja creando una tabla intermedia

CREATE TABLE IF NOT EXISTS transactions_products (
    transactions_products_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(255),
    product_id INT UNSIGNED,

    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

##### rellenamos transactions_products
## hasta aquí todo se hizo sin la ayuda de IA
INSERT INTO transactions_products (transaction_id, product_id)

WITH RECURSIVE productos_separados AS (
    -- CASO BASE
    SELECT
        id AS transaction_id,
        CAST(
            SUBSTRING_INDEX(product_ids, ',', 1)
            AS UNSIGNED
        ) AS product_id,
        SUBSTRING(
            product_ids,
            LOCATE(',', product_ids) + 1
        ) AS resto
    FROM transactions
    WHERE product_ids IS NOT NULL
    AND product_ids LIKE '%,%'

    UNION ALL

    -- PARTE RECURSIVA
    SELECT
        transaction_id,
        CAST(
            SUBSTRING_INDEX(resto, ',', 1)
            AS UNSIGNED
        ),
        SUBSTRING(
            resto,
            LOCATE(',', resto) + 1
        )

    FROM productos_separados
    WHERE resto LIKE '%,%'

    UNION ALL

    -- ÚLTIMO PRODUCTO
    SELECT
        transaction_id,
        CAST(resto AS UNSIGNED),
        NULL
    FROM productos_separados
    WHERE resto NOT LIKE '%,%'
)

SELECT
    transaction_id,
    product_id
FROM productos_separados;

""" 👉 Necessitem conèixer el nombre de vegades que s'ha venut cada producte. """

SELECT p.product_name, COUNT(*) AS total
FROM transactions_products AS tp
JOIN transactions AS t
ON tp.transaction_id = t.id
JOIN products AS p
ON tp.product_id = p.id
WHERE t.declined = 0
GROUP BY tp.product_id
ORDER BY total DESC;

######################################################################
