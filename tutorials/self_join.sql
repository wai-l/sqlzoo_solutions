-- Self JOIN - Edinburgh Buses
--10
-- Find the routes involving two buses that can go from Craiglockhart to Lochend.
-- Show the bus no. and company for the first bus, the name of the stop for the transfer, and the bus no. and company for the second bus.
-- Hint
-- Self-join twice to find buses that visit Craiglockhart and Lochend, then join those on matching stops.

WITH c_routes AS (
    SELECT num, company
    FROM route LEFT JOIN stops ON route.stop = stops.id
    WHERE stops.name = 'Craiglockhart'
), 
c_stops AS (
    SELECT c_routes.num, c_routes.company, stops.name
    FROM c_routes
    INNER JOIN route ON c_routes.num = route.num AND c_routes.company = route.company
    LEFT JOIN stops ON route.stop = stops.id
    WHERE stops.name !='Craiglockhart'
), 
l_routes AS (
    SELECT num, company, stops.name
    FROM route LEFT JOIN stops ON route.stop = stops.idœ
    WHERE stops.name = 'Lochend'
), 
l_stops AS (
    SELECT l_routes.num, l_routes.company, stops.name
    FROM l_routes
    INNER JOIN route ON l_routes.num = route.num AND l_routes.company = route.company
    LEFT JOIN stops ON route.stop = stops.id
    WHERE stops.name !='Lochend'
)
SELECT c_stops.num, c_stops.company, c_stops.name, l_stops.num, l_stops.company
FROM l_stops INNER JOIN c_stops ON l_stops.name = c_stops.name
ORDER BY c_stops.num, c_stops.name, l_stops.num

-- alternative solution
-- instead of using multiple CTEs to join the route and stops, only have 2 CTEs in which the stops are joined to the route.
WITH craig_stops AS (
    SELECT r.num, r.company, s.name
    FROM route AS r JOIN stops AS s ON r.stop = s.id
    WHERE (r.num, r.company) IN (
        SELECT num, company FROM route LEFT JOIN stops ON route.stop = stops.id WHERE name = 'Craiglockhart')
    AND s.name != 'Craiglockhart'), 
loch_stops AS (
    SELECT r.num, r.company, s.name
    FROM route AS r JOIN stops AS s ON r.stop = s.id
    WHERE (r.num, r.company) IN (
        SELECT num, company FROM route LEFT JOIN stops ON route.stop = stops.id WHERE name = 'Lochend')
    AND s.name != 'Lochend'
)
SELECT craig_stops.num, craig_stops.company, craig_stops.name, loch_stops.num, loch_stops.company
FROM craig_stops INNER JOIN loch_stops ON craig_stops.name = loch_stops.name
ORDER BY craig_stops.num, craig_stops.name, loch_stops.num
