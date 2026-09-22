-- 1. Count the number of Movies vs TV Shows

SELECT TYPE, COUNT(*) AS TOTAL
FROM NETFLIX
GROUP BY 1


-- 2. Find the most common rating for movies and TV shows

WITH RATING_CNT AS(
SELECT TYPE, RATING, COUNT(*) AS CNT
FROM NETFLIX
GROUP BY 1,2
),
FT AS (
SELECT *, RANK() OVER(PARTITION BY TYPE ORDER BY CNT DESC) AS RNK
FROM RATING_CNT
)

SELECT TYPE, RATING, CNT
FROM FT
WHERE RNK = 1;


-- 3. List all movies released in a specific year (e.g., 2020)

SELECT *
FROM NETFLIX
WHERE TYPE = "Movie" AND RELEASE_YEAR = 2020


-- 4. Find the top 5 countries with the most content on Netflix

SELECT TRIM(JT.COUNTRY), COUNT(*) AS CNT
FROM NETFLIX 
CROSS JOIN JSON_TABLE(
CONCAT('["', REPLACE(COUNTRY, ',' , '","') , '"]' ),
'$[*]'
COLUMNS(COUNTRY VARCHAR(50) PATH '$')
) AS JT
GROUP BY 1 
ORDER BY CNT DESC
LIMIT 5;


-- 5. Identify the longest movie

SELECT *
FROM NETFLIX
WHERE TYPE = "MOVIE"
ORDER BY CAST(DURATION AS UNSIGNED) DESC
LIMIT 1;

-- 6. Find content added in the last 5 years

SELECT *
FROM NETFLIX
WHERE str_to_date(DATE_ADDED, "%M %d, %Y") >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT *
FROM NETFLIX CROSS JOIN
JSON_TABLE(CONCAT('["', REPLACE(DIRECTOR, ',', '","'), '"]' ), '$[*]' COLUMNS(DIRECTOR VARCHAR(50) PATH '$')) AS JT
WHERE TRIM(JT.DIRECTOR) = "Rajiv Chilaka";

-- 8. List all TV shows with more than 5 seasons

SELECT *
FROM NETFLIX
WHERE TYPE = 'TV Show'
  AND CAST(DURATION AS UNSIGNED) > 5;


-- 9. Count the number of content items in each genre

SELECT TRIM(JT.GENRE), COUNT(*)
FROM NETFLIX 
CROSS JOIN
JSON_TABLE(
CONCAT('["' , REPLACE(LISTED_IN, ',', '","'), '"]'), "$[*]" 
COLUMNS(GENRE VARCHAR(50) PATH '$') 
) AS JT
GROUP BY 1

-- 10. Find each year and the average numbers of content release by India on netflix. 
-- return top 5 year with highest avg content release !

WITH FT AS(
SELECT COUNT(*) AS TOTAL
FROM NETFLIX 
CROSS JOIN JSON_TABLE(
CONCAT('["', REPLACE(COUNTRY, ',' , '","') , '"]' ),
'$[*]'
COLUMNS(COUNTRY VARCHAR(50) PATH '$')
) AS JT
WHERE TRIM(JT.COUNTRY) = "INDIA"

)

SELECT RELEASE_YEAR, COUNT(*) AS CNT, (100.00* count(*)/ FT.TOTAL) AS PER
FROM NETFLIX 
CROSS JOIN JSON_TABLE(
CONCAT('["', REPLACE(COUNTRY, ',' , '","') , '"]' ),
'$[*]'
COLUMNS(COUNTRY VARCHAR(50) PATH '$')
) AS JT CROSS JOIN FT
WHERE TRIM(JT.COUNTRY) = "INDIA"
GROUP BY 1, FT.TOTAL
ORDER BY PER DESC
LIMIT 5;

-- 11. List all movies that are documentaries

SELECT *
FROM NETFLIX 
CROSS JOIN JSON_TABLE(
CONCAT('["', REPLACE(LISTED_IN, ',' , '","') , '"]' ),
'$[*]'
COLUMNS(GENERE VARCHAR(50) PATH '$')
) AS JT
WHERE TRIM(JT.GENERE) = "DOCUMENTARIES"

-- 12. Find all content without a director

SELECT *
FROM NETFLIX
WHERE DIRECTOR IS NULL;


-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT COUNT(*)
FROM NETFLIX
WHERE CAST_MEMBERS  LIKE "%Salman Khan%" and RELEASE_YEAR >= YEAR(CURDATE()) - 10;


-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT TRIM(JT.MEMBERS), COUNT(*) AS CNT
FROM NETFLIX 
CROSS JOIN JSON_TABLE(
CONCAT('["', REPLACE(CAST_MEMBERS, ',' , '","') , '"]' ),
'$[*]'
COLUMNS(MEMBERS VARCHAR(50) PATH '$')
) AS JT
WHERE COUNTRY = "India"
GROUP BY 1
ORDER BY CNT DESC
LIMIT 10;

-- Question 15:
-- Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.

WITH FT AS (SELECT *, CASE WHEN DESCRIPTION LIKE "%KILL%" OR DESCRIPTION LIKE "%violence%" THEN "BAD" ELSE "GOOD" END AS LABEL
FROM NETFLIX
)

SELECT LABEL, COUNT(*) AS CNT
FROM FT
GROUP BY LABEL