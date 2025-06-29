-- Window fuinctions - COVID

-- 2. Introducing the LAG function
-- The LAG function is used to show data from the preceding row or the table. When lining up rows the data is partitioned by country name and ordered by the data whn. That means that only data from Italy is considered.
-- Modify the query to show confirmed for the day before.
SELECT 
    name, 
    DAY(whn), 
    confirmed, 
    LAG(confirmed, 1) OVER (PARTITION BY name ORDER BY whn) AS dbf
FROM covid
WHERE 
    name = 'Italy'
    AND MONTH(whn) = 3 
    AND YEAR(whn) = 2020
ORDER BY whn

-- 4. Weekly changes
-- The data gathered are necessarily estimates and are inaccurate. However by taking a longer time span we can mitigate some of the effects.
-- You can filter the data to view only Monday's figures WHERE WEEKDAY(whn) = 0.
-- Show the number of new cases in Italy for each week in 2020 - show Monday only.
WITH italy_weekly_cases AS (
    SELECT 
        name, 
        DATE_FORMAT(whn,'%Y-%m-%d') AS date, 
        confirmed, 
        LAG(confirmed, 1) OVER (PARTITION BY name ORDER BY whn) AS wbf
    FROM covid
    WHERE 
        name = 'Italy'
        AND WEEKDAY(whn) = 0 
        AND YEAR(whn) = 2020
    ORDER BY whn
)
SELECT name, date, confirmed - wbf AS new_cases
FROM italy_weekly_cases

-- 5. LAG using a JOIN
-- You can JOIN a table using DATE arithmetic. This will give different results if data is missing.
-- Show the number of new cases in Italy for each week - show Monday only.
-- In the sample query we JOIN this week tw with last week lw using the DATE_ADD function.
SELECT 
    tw.name, 
    DATE_FORMAT(tw.whn,'%Y-%m-%d'), 
    tw.confirmed - lw.confirmed
FROM covid tw 
LEFT JOIN covid lw ON 
    DATE_ADD(lw.whn, INTERVAL 1 WEEK) = tw.whn
    AND tw.name=lw.name
WHERE tw.name = 'Italy' AND WEEKDAY(tw.whn) = 0
ORDER BY tw.whn

-- 7. Infection rate
-- This query includes a JOIN to the world table so we can access the total population of each country and calculate infection rates (in cases per 100,000).
-- Show the infection rate ranking for each country. Only include countries with a population of at least 10 million.
WITH ir AS (
    SELECT covid.name, population, (100000*confirmed/population) AS infection_rate
    FROM covid
    LEFT JOIN world ON covid.name = world.name
    WHERE population >= 10000000 AND whn = '2020-04-20')
SELECT name, ROUND(infection_rate, 2), 
    RANK() OVER(ORDER BY infection_rate)
FROM ir
ORDER BY population DESC

-- 8. Turning the corner
-- For each country that has had at last 1000 new cases in a single day, show the date of the peak number of new cases.
WITH dbf_table AS ( 
    SELECT 
        name, 
        whn, 
        confirmed, 
        LAG(confirmed, 1) OVER (PARTITION BY name ORDER BY whn) AS dbf
    FROM covid
    ), 
thousands_cases_country AS (
    SELECT 
        name, whn, confirmed, dbf, 
        RANK() OVER (PARTITION BY name ORDER BY confirmed-dbf DESC) AS rank
    FROM dbf_table
    WHERE (confirmed-dbf) >= 1000
    )
SELECT name, DATE_FORMAT(whn, '%Y-%m-%d'), (confirmed-dbf) AS new_cases
FROM thousands_cases_country
WHERE rank = 1
ORDER BY whn

-- Another option is to join the two tables, with thousands_case_country is the group by Max without date. 
