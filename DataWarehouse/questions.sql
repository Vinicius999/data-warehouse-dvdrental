-- Questões - Star Schema

-- 1. Qual filme gerou mais receita ($$$) para a empresa?
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
 --ORDER BY rental_id
 ) a
 GROUP BY film
 ORDER BY receita DESC
 LIMIT 10;


-- 2. Qual a categoria de filme mais locada?
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
	--GROUP BY c.category_id, c.category
	--ORDER BY fr.rental_id
 ) AS a
 GROUP BY category
 ORDER BY num_rentals DESC
 LIMIT 5;


-- 3. De qual cidade são os clientes que mais locam filmes?
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


-- 4. Ranking dos 10 atores/atrizes que mais tiveram filmes locados?
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
 LIMIT 10;





