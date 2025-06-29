-- The Join operation
-- 13. List every match with the goals scored by each team as shown. This will use "CASE WHEN" which has not been explained in any previous exercises. 
-- Notice in the query given every goal is listed. If it was a team1 goal then a 1 appears in score1, otherwise there is a 0. You could SUM this column to get a count of the goals scored by team1. Sort your result by mdate, matchid, team1 and team2.

SELECT mdate,
  team1,
  SUM(
    CASE WHEN teamid=team1 THEN 1 ELSE 0 END
    ) AS score1, 
  team2, 
  SUM(
    CASE WHEN teamid=team2 THEN 1 ELSE 0 END
    ) AS score2
  FROM game LEFT JOIN goal ON matchid = id
  GROUP BY mdate, team1, team2
  ORDER BY mdate, matchid, team1, team2