<h1 align="center"> Desafio Desenvolve - Data Warehouse </h1>

<p align="center">Este repositório contém o 3º desafio da mentoria individual do <a href="https://desenvolve.grupoboticario.com.br/">Programa Desenvolve 2023 - Trilha Dados</a>. O desafio se trata da construção de um <strong>data warehouse</strong> simples em PostgreSQL a partir de um banco de dados de exemplo, seguindo a lógica do modelo <strong>Star Schema</strong>.<p>
<p align="center">
    <a href="##Desafio">Desafio</a> |
    <a href="##Tecnologias">Tecnologias</a> |
    <a href="##Dados">Dados</a> |
    <a href="##Data warehouse">Data warehouse</a>
</p>

## Desafio

O desafio se trata da construção de um <strong>data warehouse</strong> simples em PostgreSQL. A proposta é utilizar o banco de dados de exemplo, e a partir dele criar uma nova estrutura seguindo a lógica do modelo <strong>Star Schema</strong>, e após realizar a denormalização de alguns dados para leitura em sistemas de BI.

O data warehouse deve responder às seguintes perguntas:

1. Qual filme gerou mais receita ($$$) para a empresa? 
2. Qual a categoria de filme mais locada? 
3. De qual cidade são os clientes que mais locam filmes? 
4. Ranking dos 10 atores/atrizes que mais tiveram filmes locados?

Premissas:

- Você deve seguir o modelo estrela para modelagem de dados.
- O modelo estrela deve ter apenas uma tabela fato. 
- O modelo pode ter quantas tabelas dimenssões forem necessárias.

Obs.: o modelo estrela não permite mais de 1 nível de relacionamento entre tabelas, portanto uma tabela fato central pode estar ligada a N dimensões, mas uma dimensão só pode ter ligação com a tabela fato

## Tecnologias

<p style='margin: 16px 4px 32px;'>
    <a href="https://www.postgresql.org/" target="_blank" rel="noreferrer">
        <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" alt="Vini-Postgress" height="40" width="40" >
    </a>
</p>

## Dados

- Fonte dos dados: [dvdrental](https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip)

- Diagrama de entidade relacionamento do banco de dados: https://www.postgresqltutorial.com/wp-content/uploads/2018/03/printable-postgresql-sample-database-diagram.pdf

## Data warehouse 

#### 1 - Carregar a base de dados no PostgreSQL

Com o banco de dados já criado, o carregamento da base de dados no banco foi realizado seguindo o seguinte passo a passo: [link](https://www.postgresqltutorial.com/postgresql-getting-started/load-postgresql-sample-database/)

#### 2 - Denormalização e Modelagem física do Data Warehouse

Antes da implementação, foi desenvolvida a [modelagem física](https://github.com/Vinicius999/data-warehouse-dvdrental/tree/main/DataWarehouse/star_schema_modeling) do Data Warehouse no modelo Star Schema usando o [SQL Power Architect](https://bestofbi.com/architect-download/):

![](https://github.com/Vinicius999/data-warehouse-dvdrental/blob/main/DataWarehouse/star_schema_modeling/star_schema_modeling.png)

#### 3 - Criação do DW no modelo Star Schema e população das tabelas

Seguindo a modelagem física, foram criadas as novas tabelas em um novo schema chamado **dw**, que será o nosso Data Warehouse:

```postgresql
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
```

Em seguida, populamos as tabelas do nosso Data warehouse:

```postgresql
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
```

#### 4 - Resolução das questões

1. Qual filme gerou mais receita ($$$) para a empresa?

   ```postgresql
   SELECT
   	film,
   	SUM(amount) AS receita
    FROM(
   	SELECT DISTINCT
   		f.film_id,
   		f.film,
   		fr.rental_id,
   		fr.amount
   	 FROM dw."DIM_film" f
   	 LEFT JOIN dw."FACT_rental" fr ON f.film_id = fr.film_id
   	 WHERE amount IS NOT NULL
    ) a
    GROUP BY film
    ORDER BY receita DESC
    LIMIT 5;
   ```

2. Qual a categoria de filme mais locada?

   ```postgresql
   SELECT
   	category,
   	COUNT(category_id) AS num_rentals
    FROM(
   	SELECT DISTINCT
   		c.category_id,
   		c.category,
   		fr.rental_id
   	FROM dw."DIM_category" c
   	LEFT JOIN dw."FACT_rental" fr ON c.category_id = fr.category_id
    ) AS a
    GROUP BY category
    ORDER BY num_rentals DESC
    LIMIT 5;
   ```

3. De qual cidade são os clientes que mais locam filmes?

   ```postgresql
   SELECT
   	city,
   	COUNT(city_id) AS num_rentals
    FROM(
   	SELECT DISTINCT
   		a.city_id,
   		a.city,
   		fr.rental_id,
   		c.customer_id
   	FROM dw."DIM_address" a
   	LEFT JOIN dw."FACT_rental" fr ON a.address_id = fr.address_id
   	LEFT JOIN dw."DIM_customer" c ON c.customer_id = fr.customer_id
   	ORDER BY fr.rental_id
    ) AS a
    GROUP BY city
    ORDER BY num_rentals DESC
    LIMIT 5;
   ```

4. Ranking dos 10 atores/atrizes que mais tiveram filmes locados?

   ```postgresql
   SELECT
   	actor,
   	COUNT(actor_id) AS num_rentals
    FROM(
   	SELECT DISTINCT
   		a.actor_id,
   		(a.first_name || ' ' || a.last_name) AS actor,
   		fr.rental_id
   	FROM dw."DIM_actor" a
   	LEFT JOIN dw."FACT_rental" fr ON a.actor_id = fr.actor_id
   	ORDER BY fr.rental_id
    ) AS a
    GROUP BY actor
    ORDER BY num_rentals DESC
    LIMIT 5;
   ```

   
