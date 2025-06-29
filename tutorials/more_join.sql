
-- More JOIN operations

-- 8. Harrison Ford movies
-- List the films in which 'Harrison Ford' has appeared

SELECT movie.title AS films
FROM movie
JOIN casting
ON movie.id = casting.movieid
JOIN (
    SELECT actor.id
    FROM actor
    WHERE actor.name = 'Harrison Ford'
) AS filtered_actor ON casting.actorid = filtered_actor.id

-- 12. Lead actor in Julie Andrews movies
-- List the film title and the leading actor for all of the films 'Julie Andrews' played in. 
WITH ja_movies AS (
    SELECT DISTINCT movieid
    FROM casting
    LEFT JOIN actor ON casting.actorid = actor.id
    WHERE actor.name = 'Julie Andrews'
)
SELECT movie.title, actor.name
FROM casting
LEFT JOIN movie ON casting.movieid = movie.id
LEFT JOIN actor ON casting.actorid = actor.id
WHERE casting.ord=1 AND movieid IN (SELECT movieid FROM ja_movies)

-- 15. with 'Art Garfunkel'
-- List all the people who have worked with 'Art Garfunkel'.
WITH AG_movies AS (
    SELECT movieid
    FROM casting
    WHERE actorid = (SELECT id FROM actor WHERE name = 'Art Garfunkel')
    )
SELECT actor.name
FROM actor
LEFT JOIN casting ON actor.id = casting.actorid
WHERE casting.movieid IN (SELECT movieid FROM AG_movies) AND actor.name != 'Art Garfunkel'

