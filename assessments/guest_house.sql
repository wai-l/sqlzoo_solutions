-- Guest House

-- 7. Including Extras. Calculate the total bill for booking 5346 including extras.
-- Union/merge example
WITH room_amount AS (
    SELECT rate.amount*booking.nights AS amount
    FROM booking
    LEFT JOIN rate ON booking.room_type_requested = rate.room_type AND booking.occupants = rate.occupancy
    WHERE booking.booking_id = 5346
), 
extra_amount AS (
    SELECT amount 
    FROM extra
    WHERE booking_id = 5346
)
SELECT SUM(amount)
FROM (
    SELECT amount FROM room_amount
    UNION ALL
    SELECT amount FROM extra_amount)
AS combined_amounts

-- 9. How busy are we? For each day of the week beginning 2016-11-25 show the number of bookings starting that day. Be sure to show all the days of the week in the correct order.
-- use recursive CTE to generate the date series/date spine for the week
WITH RECURSIVE date_series AS (
    SELECT DATE('2016-11-25') AS date, 1 AS day_count
    UNION ALL
    SELECT date + INTERVAL 1 DAY, day_count + 1
    FROM date_series
    WHERE day_count < 7
)
SELECT DATE_FORMAT(date_series.date, '%Y-%m-%d') AS date, COUNT(booking_id) AS arrivals
FROM date_series LEFT JOIN booking 
ON date_series.date = booking.booking_date
GROUP BY date_series.date 
ORDER BY date_series.date

-- 11. Coincidence 
-- Have two guests with the same surname ever stayed in the hotel on the evening? Show the last name and both first names. Do not include duplicates.

-- solution 1
WITH t1 AS (
    SELECT guest.id, guest.first_name, guest.last_name, booking.booking_date, booking.nights
    FROM booking INNER JOIN guest ON booking.guest_id = guest.id
), 
t2 AS (
    SELECT guest.id, guest.first_name, guest.last_name, booking.booking_date, booking.nights
    FROM booking INNER JOIN guest ON booking.guest_id = guest.id
), 
joined AS (
    SELECT 
        t1.last_name, 
        t1.first_name AS guest_1_first_name,  
        t2.first_name AS guest_2_first_name
    FROM t1 
    JOIN t2 
    ON t1.last_name = t2.last_name 
    AND t1.id < t2.id -- avoid self join and duplicate
    WHERE t1.booking_date BETWEEN t2.booking_date AND DATE_ADD(t2.booking_date, INTERVAL t2.nights - 1 DAY)
    OR t2.booking_date BETWEEN t1.booking_date AND DATE_ADD(t1.booking_date, INTERVAL t1.nights - 1 DAY)
)
SELECT DISTINCT *
FROM joined
ORDER BY last_name

-- solution 2
-- solution found online, answered the question but with risk
SELECT b.last_name, b.first_name, a.first_name
FROM
(SELECT *
FROM guest JOIN booking ON guest.id = booking.guest_id) AS a
JOIN
(SELECT *
FROM guest JOIN booking ON guest.id = booking.guest_id) AS b
ON a.last_name = b.last_name AND a.first_name <> b.first_name
WHERE (a.booking_date BETWEEN b.booking_date AND DATE_ADD(b.booking_date, INTERVAL b.nights-1 DAY)) OR (b.booking_date BETWEEN a.booking_date AND DATE_ADD(a.booking_date, INTERVAL a.nights-1 DAY))
GROUP BY a.last_name 
-- the group by here limited the result to return one row per a.last_name, 
-- however if there is more than two guests with the same last name, it will only return one row, but not all combination. 

-- 12. Check out per floor
-- The first digit of the room number indicates the floor – e.g. room 201 is on the 2nd floor. 
-- For each day of the week beginning 2016-11-14 show how many rooms are being vacated that day by floor number. Show all days in the correct order.
-- with pivot function

WITH
grouping AS (
    SELECT 
        room_no,
        booking_date,
        DATE_ADD(booking_date, INTERVAL nights DAY) AS checkout_date, 
        CASE
                WHEN room_no >= 300 THEN '3rd'
                WHEN room_no >= 200 THEN '2nd'
                ELSE '1st'
        END AS floor
    FROM booking
)
SELECT 
    checkout_date, 
    ['1st'], ['2nd'], ['3rd']
FROM (
    SELECT checkout_date, floor, room_no
    FROM grouping
) AS source_table
PIVOT (
    COUNT(room_no) FOR floor IN (['1st'], ['2nd'], ['3rd'])
) AS pivot_table
WHERE checkout_date BETWEEN '2016-11-14' AND '2016-11-20'

-- without pivot function

WITH grouping AS (
    SELECT 
        room_no,
        booking_date,
        DATE_ADD(booking_date, INTERVAL nights DAY) AS checkout_date, 
        CASE
                WHEN room_no >= 300 THEN '3rd'
                WHEN room_no >= 200 THEN '2nd'
                ELSE '1st'
        END AS floor
    FROM booking
)
SELECT 
    DATE_FORMAT(checkout_date, "%Y-%m-%d") AS checkout_date, 
    SUM(CASE WHEN floor = '1st' THEN 1 ELSE 0 END) AS '1st',
    SUM(CASE WHEN floor = '2nd' THEN 1 ELSE 0 END) AS '2nd',
    SUM(CASE WHEN floor = '3rd' THEN 1 ELSE 0 END) AS '3rd'
FROM grouping
GROUP BY checkout_date
HAVING checkout_date BETWEEN '2016-11-14' AND '2016-11-20'

-- 13. Free rooms? List the rooms that are free on the day 25th Nov 2016.
-- If you only need to check one date
SELECT id
FROM room
WHERE id NOT IN (
    SELECT room_no
    FROM booking
    WHERE DATE('2016-11-25') >= booking_date
      AND DATE('2016-11-25') < DATE_ADD(booking_date, INTERVAL nights DAY)
)

-- for date range: 
-- set a date series with set period
WITH RECURSIVE date_series AS (
    SELECT DATE('2016-11-14') AS dates
    UNION ALL
    SELECT DATE_ADD(dates, INTERVAL 1 DAY)
    FROM date_series
    WHERE DATE_ADD(dates, INTERVAL 1 DAY) <= DATE('2016-11-30') -- maximum number of dates
), 
-- create a booking period for each room
booking_period AS (
    SELECT 
        room_no,
        booking_date,
        DATE_ADD(booking_date, INTERVAL nights DAY) AS checkout_date
    FROM booking
),
-- join the two cte where date is between booking date and checkout date
expanded_dates AS (
    SELECT 
        booking_period.room_no,
        date_series.dates AS booked_date
    FROM booking_period
    JOIN date_series
    ON date_series.dates >= booking_period.booking_date 
    AND date_series.dates < booking_period.checkout_date -- this decide if checkout date is included in the period, if it is, change to <= booking_period.checkout_date
), 
-- join room_id and all possible dates within the period
room_date_grid AS (
    SELECT room.id, date_series.dates
    FROM room
    CROSS JOIN date_series
), 
room_booked_by_date AS (
    SELECT
        room_date_grid.id, 
        room_date_grid.dates, 
        expanded_dates.booked_date
    FROM room_date_grid
    LEFT JOIN expanded_dates
    ON expanded_dates.room_no = room_date_grid.id
    AND expanded_dates.booked_date = room_date_grid.dates
)
SELECT 
    id, dates
FROM room_booked_by_date
WHERE booked_date IS NULL AND dates = '2016-11-25'

-- 14. Single room for three nights required. A customer wants a single room for three consecutive nights. Find the first available date in December 2016.
WITH room_list AS (
    SELECT id
    FROM room
    WHERE room_type = 'single'
), 
single_rm_bookings AS (
    SELECT 
        room_no, 
        booking_date, 
        DATE_ADD(booking_date, INTERVAL nights DAY) AS checkout_date
    FROM booking
    WHERE room_no IN (SELECT id FROM room_list)
), 
booking_with_next AS (
    SELECT 
        room_no, 
        booking_date, 
        checkout_date, 
        LEAD(booking_date) OVER (PARTITION BY room_no ORDER BY booking_date) AS next_booking_date
    FROM single_rm_bookings
), 
vacant_days AS (
    SELECT
        room_no, 
        booking_date, 
        checkout_date, 
        next_booking_date, 
        CASE WHEN 
            next_booking_date IS NULL 
            THEN DATEDIFF('2017-01-01', checkout_date) 
            ELSE DATEDIFF(next_booking_date, checkout_date) 
        END AS no_of_days
        -- DATEDIFF(LEAD(booking_date) OVER (PARTITION BY room_no ORDER BY booking_date), checkout_date) 
    FROM booking_with_next
)
SELECT room_no, MIN(checkout_date)
FROM vacant_days
WHERE 
    no_of_days >= 3 AND MONTH(checkout_date) = 12 AND YEAR(checkout_date) = 2016
GROUP BY checkout_date
ORDER BY checkout_date
LIMIT 1

-- 15. Gross income by week 
-- Money is collected from guests when they leave. For each Thursday in November and December 2016, show the total amount of money collected from the previous Friday to that day, inclusive.

-- demonstrate how to get start and end of week
WITH RECURSIVE date_series AS (
    SELECT DATE('2016-11-01') AS dates
    UNION ALL
    SELECT dates + INTERVAL 1 DAY
    FROM date_series
    WHERE dates < DATE('2016-12-31')
), 
week_start AS (
    SELECT 
        dates, 
        (DAYOFWEEK(dates)+1)%7 AS week_day_start, 
        (4-(DAYOFWEEK(dates)-1)+7)%7 AS week_day_end, 
        DAYOFWEEK(dates) AS day_of_week,
        dates - INTERVAL ((DAYOFWEEK(dates)+1)%7) DAY AS week_start, 
        dates + INTERVAL (4-(DAYOFWEEK(dates)-1)+7)%7 DAY AS week_end
    FROM date_series
)
SELECT * 
FROM week_start

-- solution
WITH RECURSIVE date_series AS (
    SELECT DATE('2016-11-01') AS dates
    UNION ALL
    SELECT dates + INTERVAL 1 DAY
    FROM date_series
    WHERE dates < DATE('2016-12-31')
), 
end_of_week AS (
    SELECT 
        dates, 
        dates + INTERVAL (4-(DAYOFWEEK(dates)-1)+7)%7 DAY AS week_end
    FROM date_series
), 
extra_sum AS (
    SELECT 
        booking_id, 
        SUM(amount) AS amount
    FROM extra
    GROUP BY booking_id
), 
checkout_payment AS (
    SELECT 
        booking.booking_id, 
        DATE_ADD(booking.booking_date, INTERVAL booking.nights DAY) AS checkout_date, 
        rate.amount * booking.nights AS room_amount, 
        CASE 
            WHEN extra_sum.amount IS NULL THEN 0
            ELSE extra_sum.amount 
        END AS extra_amount
    FROM booking
    LEFT JOIN rate ON booking.room_type_requested = rate.room_type AND booking.occupants = rate.occupancy
    LEFT JOIN extra_sum ON booking.booking_id = extra_sum.booking_id
)
SELECT 
    DATE_FORMAT(end_of_week.week_end, "%Y-%m-%d") AS end_of_week, 
    SUM(room_amount + extra_amount) AS weekly_income
FROM checkout_payment
LEFT JOIN end_of_week ON checkout_payment.checkout_date = end_of_week.dates
GROUP BY end_of_week.week_end

-- a different approach
-- identify the week period at the end of the query
WITH RECURSIVE date_series AS (
    SELECT DATE('2016-11-01') AS date
    UNION ALL
    SELECT date + INTERVAL 1 DAY
    FROM date_series
    WHERE date < '2016-12-31'
),
thursdays AS (
    SELECT date AS week_end
    FROM date_series
    WHERE DAYOFWEEK(date) = 5 -- Thursday (Sunday = 1, so Thursday = 5)
),
extra_sum AS (
    SELECT booking_id, SUM(amount) AS extra_amount
    FROM extra
    GROUP BY booking_id
),
checkout_payment AS (
    SELECT 
        booking.booking_id, 
        DATE_ADD(booking.booking_date, INTERVAL booking.nights DAY) AS checkout_date, 
        rate.amount * booking.nights AS room_amount, 
        COALESCE(extra_sum.extra_amount, 0) AS extra_amount
    FROM booking
    LEFT JOIN rate 
        ON booking.room_type_requested = rate.room_type 
        AND booking.occupants = rate.occupancy
    LEFT JOIN extra_sum 
        ON booking.booking_id = extra_sum.booking_id
),
final AS (
    SELECT 
        week_end,
        SUM(room_amount + extra_amount) AS weekly_income
    FROM thursdays
    JOIN checkout_payment 
        ON checkout_date BETWEEN week_end - INTERVAL 6 DAY AND week_end
    GROUP BY week_end
)
SELECT 
    DATE_FORMAT(week_end, '%Y-%m-%d') AS week_ending,
    weekly_income
FROM final
ORDER BY week_ending;
