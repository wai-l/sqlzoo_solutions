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