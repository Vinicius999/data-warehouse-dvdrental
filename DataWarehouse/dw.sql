-- Criando DW: Tabelas FACT e DIMs

CREATE SCHEMA dw;

CREATE TABLE dw."DIM_film" (
    film_id INTEGER PRIMARY KEY,
    film VARCHAR(255),
    rental_rate NUMERIC(5,2)
);

CREATE TABLE dw."DIM_category" (
    category_id INTEGER PRIMARY KEY,
    category VARCHAR(25)
);

CREATE TABLE dw."DIM_actor" (
    actor_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

CREATE TABLE dw."DIM_customer" (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50)
);

CREATE TABLE dw."DIM_address" (
    address_id INTEGER PRIMARY KEY,
    address VARCHAR,
    city_id INTEGER,
    city VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE dw."DIM_dates" (
	date_id DATE PRIMARY KEY,
    date DATE,
    year INTEGER,
    quarter VARCHAR(2),
    month VARCHAR(10),
    month_number SMALLINT,
    day_of_week VARCHAR(10),
    day_number SMALLINT,
    week_of_year SMALLINT,
    holiday_flag SMALLINT
);

CREATE TABLE dw."FACT_rental" (
	rental_id INTEGER,
    film_id INTEGER REFERENCES dw."DIM_film"(film_id),
    category_id INTEGER REFERENCES dw."DIM_category"(category_id),
    actor_id INTEGER REFERENCES dw."DIM_actor"(actor_id),
    customer_id INTEGER REFERENCES dw."DIM_customer"(customer_id),
    address_id INTEGER REFERENCES dw."DIM_address"(address_id),
    date_id DATE REFERENCES dw."DIM_dates"(date_id),
    amount NUMERIC(5,2)
);


-- Populando as tabelas

INSERT INTO dw."DIM_film" (film_id, film, rental_rate)
SELECT DISTINCT
    film_id,
    title AS film,
    rental_rate
FROM film;

INSERT INTO dw."DIM_category" (category_id, category)
SELECT DISTINCT
    category_id,
    name AS category
FROM category;

INSERT INTO dw."DIM_actor" (actor_id, first_name, last_name)
SELECT DISTINCT
    actor_id,
    first_name,
    last_name
FROM actor;

INSERT INTO dw."DIM_customer" (customer_id, first_name, last_name)
SELECT DISTINCT
    customer_id,
    first_name,
    last_name
FROM customer;

INSERT INTO dw."DIM_address" (address_id, address, city_id, city, country)
SELECT DISTINCT
    a.address_id,
    a.address,
    c.city_id,
    c.city,
    co.country
FROM address a
LEFT JOIN city c ON c.city_id = a.city_id
LEFT JOIN country co ON co.country_id = c.country_id;

INSERT INTO dw."DIM_dates" (date_id, date, year, quarter, month, month_number, day_of_week, day_number, week_of_year, holiday_flag)
SELECT DISTINCT
    DATE_TRUNC('day', rental_date) AS date_key,
    DATE_TRUNC('day', rental_date) AS date,
    EXTRACT(year FROM rental_date) AS year,
    CONCAT('Q', EXTRACT(quarter FROM rental_date)) AS quarter,
    TO_CHAR(rental_date, 'Month') AS month,
    EXTRACT(month FROM rental_date) AS month_number,
    TO_CHAR(rental_date, 'Day') AS day_of_week,
    EXTRACT(day FROM rental_date) AS day_number,
    EXTRACT(week FROM rental_date) AS week_of_year,
    CASE 
        WHEN EXTRACT(MONTH FROM rental_date) = 1 AND EXTRACT(DAY FROM rental_date) = 1 THEN 1 -- Ano Novo
        WHEN EXTRACT(MONTH FROM rental_date) = 4 AND EXTRACT(DAY FROM rental_date) = 21 THEN 1 -- Tiradentes
        WHEN EXTRACT(MONTH FROM rental_date) = 5 AND EXTRACT(DAY FROM rental_date) = 1 THEN 1 -- Dia do Trabalhador
        WHEN EXTRACT(MONTH FROM rental_date) = 9 AND EXTRACT(DAY FROM rental_date) = 7 THEN 1 -- Independência
        WHEN EXTRACT(MONTH FROM rental_date) = 10 AND EXTRACT(DAY FROM rental_date) = 12 THEN 1 -- Nossa Senhora Aparecida
        WHEN EXTRACT(MONTH FROM rental_date) = 11 AND EXTRACT(DAY FROM rental_date) = 2 THEN 1 -- Finados
        WHEN EXTRACT(MONTH FROM rental_date) = 11 AND EXTRACT(DAY FROM rental_date) = 15 THEN 1 -- Proclamação da República
        WHEN EXTRACT(MONTH FROM rental_date) = 12 AND EXTRACT(DAY FROM rental_date) = 25 THEN 1 -- Natal
        ELSE 0
    END AS holiday_flag
FROM rental;

INSERT INTO dw."FACT_rental" (rental_id, film_id, category_id, actor_id, customer_id, address_id, date_id, amount)
SELECT DISTINCT
    r.rental_id,
    f.film_id,
    fc.category_id,
    fa.actor_id,
    r.customer_id,
    c.address_id,
    DATE_TRUNC('day', r.rental_date) AS date_id,
    SUM(p.amount) AS amount
FROM rental r
LEFT JOIN inventory i ON i.inventory_id = r.inventory_id
LEFT JOIN film f ON f.film_id = i.film_id
LEFT JOIN film_category fc ON fc.film_id = f.film_id
LEFT JOIN film_actor fa ON fa.film_id = f.film_id
LEFT JOIN payment p ON p.rental_id = r.rental_id
LEFT JOIN customer c ON c.customer_id = r.customer_id
GROUP BY r.rental_id, f.film_id, fc.category_id, fa.actor_id, r.customer_id, c.address_id, DATE_TRUNC('day', r.rental_date)
ORDER BY 1;




































