-- CREATE TABLES --

CREATE TABLE IF NOT EXISTS detailed
  (
     name         VARCHAR(45),
     category_id  INTEGER,
     film_id      INTEGER,
     title        VARCHAR(60),
     inventory_id INTEGER,
     rental_date  TIMESTAMP,
     rental_id    INTEGER
  );

CREATE TABLE IF NOT EXISTS summary
  (
     name  VARCHAR(45),
     count INTEGER,
     month DATE
  ); 

-- INSERT INTO DETAILED TABLE -- 

INSERT INTO detailed 
  (
     inventory_id,
     rental_date,
     rental_id,
     film_id,
     title,
     category_id,
     name
  )

SELECT r.inventory_id,
       r.rental_date,
       r.rental_id,
       i.film_id,
       f.title,
       fc.category_id,
       c.name
FROM   rental AS r
       INNER JOIN inventory AS i
               ON r.inventory_id = i.inventory_id
       INNER JOIN film AS f
               ON i.film_id = f.film_id
       INNER JOIN film_category AS fc
               ON f.film_id = fc.film_id
       INNER JOIN category AS c
               ON fc.category_id = c.category_id; 

-- DISPLAY DETAILED TABLE AND VERIFY ACCURATE DATA --

SELECT * FROM detailed;

-- TRANSFORM FUNCTION FOR DATE --

CREATE
	OR replace FUNCTION change_to_month (DATETIME TIMESTAMP without TIME zone)
RETURNS INT AS $$

DECLARE result_month INT;

BEGIN
	SELECT extract(month FROM DATETIME)
	INTO result_month;

	RETURN result_month;
END;$$

LANGUAGE plpgsql;

SELECT change_to_month();

-- TRIGGER ON DETAILED TABLE TO POPULATE SUMMARY TABLE --

CREATE FUNCTION populate_summary
  () returns TRIGGER LANGUAGE plpgsql
AS
  $$
BEGIN
  DELETE
  FROM   summary;
  
  INSERT INTO summary
              (
                    month,
                    name,
                    count
              )
  SELECT   change_to_month(rental_date) AS month,
           name,
           count(detailed.name) AS count
  FROM     detailed
  GROUP BY month,
           name
  ORDER BY month ASC,
           count DESC;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER refresh_summary
AFTER UPDATE ON detailed
FOR EACH STATEMENT
EXECUTE FUNCTION populate_summary();

-- PROCEDURE FOR TABLE REFRESH -- 

CREATE PROCEDURE refresh_tables
  () LANGUAGE plpgsql
AS
  $$
BEGIN

DELETE FROM detailed;

INSERT INTO detailed 
  (
     inventory_id,
     rental_date,
     rental_id,
     film_id,
     title,
     category_id,
     name
  )

SELECT r.inventory_id,
       r.rental_date,
       r.rental_id,
       i.film_id,
       f.title,
       fc.category_id,
       c.name
FROM   rental AS r
       INNER JOIN inventory AS i
               ON r.inventory_id = i.inventory_id
       INNER JOIN film AS f
               ON i.film_id = f.film_id
       INNER JOIN film_category AS fc
               ON f.film_id = fc.film_id
       INNER JOIN category AS c
               ON fc.category_id = c.category_id; 

PERFORM change_to_month();
END; $$;

CALL refresh_tables();

-- DISPLAY SUMMARY TABLE -- 

SELECT * FROM summary;
