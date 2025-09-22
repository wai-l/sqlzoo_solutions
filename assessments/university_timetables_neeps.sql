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

-- 12. Produce a table showing the utilisation rate and the occupancy level for all rooms with a capacity more than 60.
-- Definitions: 
    -- Utilisation rate
        -- How often a room is used relative to the total available time. 
        -- Utilisation rate = total hours of events in the room / total hours available (we will get the total hours available by querying the event table)
    -- Occupancy level: 
        -- What it measures: How full a room is when it’s being used.
        -- Occupancy level = average number of students when occupied / room capacity
-- Use inner join: ignore events with no room or no students attending

-- 1. Querty to check occupacny rate
-- A lot of rooms are overused, it could be that the room capacity is not accurate. For example, room co.B7 is showing different capacity in the SQLZOO front end VS query. 
-- The final query will be assuming that the capacity from the query is correct instead of the front end one. 
-- It will mean that over half of the rooms are overused. 
-- There is also only 1 room with capaicty more than 60 in the queried table. 

-- Student size needs to be summarised before used to join the event table, this is because there are multiple group of students attending an event at the same time. 
WITH 
    event_sze AS (
        SELECT
            attends.event, 
            SUM(student.sze) AS student_sze
        FROM attends
        INNER JOIN student ON attends.student = student.id
        GROUP BY attends.event
    ), 
    schedule AS (
        SELECT 
            event.id AS event, 
            event.dow, event.tod, event.duration, event.room, 
            event_sze.student_sze
        FROM event
        INNER JOIN event_sze ON event.id = event_sze.event
        ), 
    room_occupancy AS (
        SELECT
            schedule.room, 
            AVG(schedule.student_sze) AS avg_no_of_students, 
            room.capacity, 
            (AVG(schedule.student_sze) / room.capacity) AS occup_level, 
            CASE WHEN 
                (AVG(schedule.student_sze) / room.capacity) > 1 
                THEN 'Overused' 
                ELSE 'Normal' 
                END AS occup_status
        FROM schedule
        INNER JOIN room ON schedule.room = room.id
        GROUP BY schedule.room, room.capacity
    )
SELECT occup_status, COUNT(room) AS no_of_rooms, AVG(occup_level) AS avg_occup_level
FROM room_occupancy
GROUP BY occup_status; 

-- adhoc queries for sanity check
SELECT *
FROM event 
INNER JOIN attends ON event.id = attends.event
INNER JOIN student ON attends.student = student.id
WHERE room = 'co.G74'; 

WITH 
    event_sze AS (
        SELECT
            attends.event, 
            SUM(student.sze) AS student_sze
        FROM attends
        INNER JOIN student ON attends.student = student.id
        GROUP BY attends.event
    ), 
SELECT *
FROM event
LEFT JOIN event_sze ON event.id = event_sze.event
WHERE event.room = 'co.G74'; 

-- Let's see what's the earliest time an event start, and latest when it ends
WITH 
    event_time AS (
        SELECT 
            id, 
            dow, 
            tod, 
            CAST(SUBSTR(event.tod,1,2) AS INT) AS start_hour, -- all events start on the hour; this is an alternative as the time couldn't be parsed as time or datetime in sqlzoo
            CAST(SUBSTR(event.tod,1,2) AS INT) + event.duration AS end_hour
        FROM event
    )
SELECT dow, MIN(start_hour), MAX(end_hour)
FROM event_time
GROUP BY dow; 
-- In most days events start at 9:00 and end at 18:00, but on Tuesday there's an event that ends at 21:00
-- This means we want to calculate the utilisation rate by assuming rooms can be used 5 days a week, from 9:00 to 21:00 every day

-- Final query
-- To make the query more intersting, switch the criteria to capacity more than 30
WITH 
    count_week AS (
        SELECT COUNT(DISTINCT week) AS no_of_weeks
        FROM occurs
    ), 
    hours_per_week AS (
        SELECT 5 * (21 - 9) AS hours_per_week -- assuming rooms can be used 5 days a week, from 9:00 to 21:00 every day
    ), 
    hours_per_sem AS (
        SELECT (SELECT no_of_weeks FROM count_week) * (SELECT hours_per_week FROM hours_per_week) AS hours_per_sem
    ), 
    event_sze AS (
        SELECT
            attends.event, 
            SUM(student.sze) AS student_sze
        FROM attends
        INNER JOIN student ON attends.student = student.id
        GROUP BY attends.event
    ), 
    event_weeks AS (
        SELECT 
            event, COUNT(DISTINCT week) AS total_week
        FROM occurs
        GROUP BY event
    ), 
    schedule AS (
        SELECT 
            event.id AS event, 
            event.dow, event.tod, event.duration, event.room, 
            event_sze.student_sze, 
            event_weeks.total_week * event.duration AS total_event_hours
        FROM event
        INNER JOIN event_sze ON event.id = event_sze.event
        INNER JOIN event_weeks ON event.id = event_weeks.event
        ), 
    room_metrics AS (
        SELECT
            schedule.room, 
            AVG(schedule.student_sze) AS avg_no_of_students, 
            room.capacity, 
            (AVG(schedule.student_sze) / room.capacity) AS occup_level, 
            SUM(schedule.total_event_hours) AS total_used_hours, 
            (SUM(schedule.total_event_hours) / (SELECT hours_per_sem FROM hours_per_sem)) AS util_rate, 
            (SELECT hours_per_sem FROM hours_per_sem) AS total_available_hours
        FROM schedule
        INNER JOIN room ON schedule.room = room.id
        WHERE room.capacity > 30
        GROUP BY schedule.room, room.capacity
    )
SELECT *
FROM room_metrics; 