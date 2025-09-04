-- University Timetables (neeps)

-- Easy Questions
-- 5. Give a list of the student groups which take modules with the word 'Database' in the name.
SELECT DISTINCT s.id, s.name -- brings in the id as well, as there is a id with no name. 
FROM modle AS m
INNER JOIN event AS e ON m.id = e.modle
INNER JOIN attends AS a ON e.id = a.event
INNER JOIN student AS s ON a.student = s.id
WHERE m.name LIKE '%Database%'

-- Medium Questions
-- 6. Show the 'size' of each of the co72010 events. Size is the total number of students attending each event.
SELECT e.id AS event, SUM(s.sze) AS total_no_of_students
FROM event AS e
LEFT JOIN attends AS a
ON e.id = a.event
LEFT JOIN student AS s
ON a.student = s.id
WHERE e.modle = 'co72010' 
GROUP BY e.id
ORDER BY total_no_of_students DESC

-- 7. For each post-graduate module, show the size of the teaching team. (post graduate modules start with the code co7).
SELECT e.modle, COUNT(DISTINCT staff)
FROM event AS e
LEFT JOIN teaches
ON e.id = teaches.event
GROUP BY e.modle
HAVING e.modle LIKE 'co7%'


-- 8. Give the full name of those modules which include events taught for fewer than 10 weeks.
-- use this to first check the data type of the table columns, as the week column looks like a string instead of a number
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'occurs'
-- all columns data type shown as varchar

-- the actual query returning the result
-- force the week column to be treated as a number
-- this assume the events are consecutive
WITH week_as_int AS(
    SELECT event, CAST(week AS INT) AS week
    FROM occurs
), 
event_duration AS (
    SELECT 
        event, 
        MAX(week) - MIN(week) AS duration
    FROM week_as_int
    GROUP BY event
    HAVING (MAX(week) - MIN(week)) <= 10
    ORDER BY duration
)
SELECT DISTINCT modle.id, modle.name
FROM modle
INNER JOIN event ON modle.id = event.modle
WHERE event.id IN (SELECT event FROM event_duration); 

-- alternatively, just count the number of weeks appears in the occurs table
-- this means that we are only counting weeks where the events occured
-- so if an event happened from week 1 to week 5, then week 7 to week 10, it will not be counted as 10 weeks, therefore filtered from the CTE
WITH 10_weeks_event AS (
    SELECT event
    FROM occurs
    GROUP BY event
    HAVING COUNT(DISTINCT week) < 10
)
SELECT DISTINCT modle.id, modle.name
FROM modle
INNER JOIN event ON modle.id = event.modle
WHERE event.id IN (SELECT event From 10_weeks_event);

-- 9. Identify those events which start at the same time as one of the co72010 lectures.
WITH event_co72010 AS (
    SELECT id, modle, dow, tod
    FROM event
    WHERE modle = 'co72010' 
    AND kind = 'L' -- only consider lectures, not labs or tutorials
)
SELECT e.*
FROM event AS e
INNER JOIN event_co72010 AS c
ON e.dow = c.dow AND e.tod = c.tod
WHERE e.modle <> 'co72010';