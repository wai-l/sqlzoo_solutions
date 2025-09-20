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

-- 10. How many members of staff have contact time which is greater than the average?
-- this will include all staff including those with no event
-- average contact time is defined as the number of hour the staffs teaches an event
-- staff with no associted events will have a contact time of 0 and included in the average
-- there are event associated with more than 1 staff; in those cases all staffs assocaited are getting full credit for the contact hours
-- e.g. if there is an event that last for 1 hour and associated with 3 staffs, each staff will have a contact hour of 1 from that event

-- solution 1
-- result: 31
WITH 
total_contact_by_staff AS (
    SELECT 
        staff.id AS staff_id, 
        staff.name AS staff_name, 
        COALESCE(SUM(event.duration), 0) AS total_contact_hours
    FROM staff 
    LEFT JOIN teaches ON staff.id = teaches.staff
    LEFT JOIN event ON teaches.event = event.id
    GROUP BY staff.id, staff.name
), 
avg_contact_by_staff AS (
    SELECT AVG(total_contact_hours) AS avg_contact_hours
    FROM total_contact_by_staff
)
SELECT COUNT(DISTINCT staff_id)
FROM total_contact_by_staff
WHERE total_contact_hours > (SELECT avg_contact_hours FROM avg_contact_by_staff); 

-- solution 2: remove the 2nd CTE
-- result: 31
WITH 
total_contact_by_staff AS (
    SELECT 
        staff.id AS staff_id, 
        staff.name AS staff_name, 
        COALESCE(SUM(event.duration), 0) AS total_contact_hours
    FROM staff 
    LEFT JOIN teaches ON staff.id = teaches.staff
    LEFT JOIN event ON teaches.event = event.id
    GROUP BY staff.id, staff.name
)
SELECT COUNT(DISTINCT staff_id)
FROM total_contact_by_staff
WHERE total_contact_hours > (SELECT AVG(total_contact_hours) FROM total_contact_by_staff); 

-- solution 3: this only count staff that have events associated with them
-- result: 17
WITH 
total_contact_by_staff AS (
    SELECT 
        teaches.staff AS staff_id, 
        -- staff.name AS staff_name, 
        COALESCE(SUM(event.duration), 0) AS total_contact_hours
    FROM teaches
    -- LEFT JOIN teaches ON staff.id = teaches.staff
    LEFT JOIN event ON teaches.event = event.id
    GROUP BY teaches.staff
)
SELECT COUNT(DISTINCT staff_id)
FROM total_contact_by_staff
WHERE total_contact_hours > (SELECT AVG(total_contact_hours) FROM total_contact_by_staff); 

-- 11. co.CHt is to be given all the teaching that co.ACg currently does. Identify those events which will clash.
WITH 
schedule AS (
    SELECT 
        teaches.staff, 
        event.id, 
        event.dow, 
        event.tod, 
        CAST(SUBSTR(event.tod,1,2) AS INT) AS start_hour, -- all events start on the hour; this is an alternative as the time couldn't be parsed as time or datetime in sqlzoo
        CAST(SUBSTR(event.tod,1,2) AS INT) + event.duration AS end_hour, 
        occurs.week
        FROM event 
    LEFT JOIN teaches ON event.id = teaches.event
    LEFT JOIN occurs ON event.id = occurs.event
    WHERE teaches.staff IN ('co.CHT', 'co.ACg')
    ), 
cht AS (
    SELECT * 
    FROM schedule
    WHERE staff = 'co.CHT'
    ),
acg AS (  
    SELECT * 
    FROM schedule
    WHERE staff = 'co.ACg'
    )
SELECT DISTINCT
    cht.id AS cht_id, 
    acg.id AS acg_id
FROM cht
INNER JOIN acg
ON 
    cht.dow = acg.dow
    AND cht.week = acg.week
    AND cht.start_hour < acg.end_hour
    AND acg.start_hour < cht.end_hour;