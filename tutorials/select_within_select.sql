-- SELECT within SELECT Tutorial
--  7. Largest in each continent
-- Find the largest country (by area) in each continent, show the continent, the name and the area:
-- The above example is known as a correlated or synchronized sub-query.

SELECT continent, name, area
FROM world x
WHERE area >= ALL(
    SELECT area 
    FROM world y
    WHERE x.continent = y.continent
    )

-- 8. First country of each continent (alphabetically)
-- List each continent and the name of the country that comes first alphabetically. 
SELECT continent, name
FROM world x
WHERE name <= ALL(
    SELECT name
    FROM world y
    WHERE x.continent = y.continent)
ORDER BY continent

-- SELECT within SELECT Tutorial
-- 9. Difficult Questions That Utilize Techniques Not Covered In Prior Sections
-- Find the continents where all countries have a population <= 25000000. 
-- Then find the names of the countries associated with these continents. Show name, continent and population.

-- Solution 1: 
WITH target_continent AS (
    SELECT DISTINCT continent
    FROM world x
    WHERE 25000000 >= ALL(
        SELECT population
        FROM world y
        WHERE x.continent = y.continent
        )
    )
SELECT name , continent, population
FROM world
WHERE continent IN (
    SELECT continent
    FROM target_continent
    )

-- Solution 2:
SELECT name, continent, population
FROM world
WHERE continent IN (
    SELECT continent
    FROM world x
    WHERE 25000000 >= ALL(
        SELECT population
        FROM world y
        WHERE x.continent = y.continent
    )
);

-- Solution 3:
SELECT name, continent, population
FROM world
WHERE continent IN (
    SELECT continent
    FROM world
    GROUP BY continent
    HAVING MAX(population) <= 25000000
);

-- 10. Three time bigger
-- Some countries have populations more than three times that of all of their neighbours (in the same continent). 
-- Give the countries and continents. 
SELECT name, continent
FROM world x
WHERE population/3 >= ALL(
    SELECT population
    FROM world y
    WHERE x.continent = y.continent AND
    x.name != y.name
    )
