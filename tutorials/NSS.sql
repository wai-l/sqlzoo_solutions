-- NSS Tutorial
-- 8. Number of Computing Students in Manchester
-- Show the institution, the total sample size and the number of computing students for institutions in Manchester for 'Q01'.
WITH comp_sci AS (
  SELECT institution, sample AS comp_sci_students
  FROM nss
  WHERE subject = '(8) Computer Science' 
    AND institution LIKE '%Manchester%' 
    AND question = 'Q01'
  )
SELECT nss.institution, SUM(nss.sample) AS total_sample, comp_sci.comp_sci_students
FROM nss
LEFT JOIN comp_sci 
ON nss.institution = comp_sci.institution
  WHERE nss.institution LIKE '%Manchester%' 
    AND nss.question = 'Q01'
GROUP BY nss.institution