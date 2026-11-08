/* ============================================================
   Chicago Crime Analysis: Districts and Map page views
   ============================================================ */

/* Slicer: district / year combinations */
CREATE VIEW DISTRICT AS
SELECT DISTINCT district, year
FROM crime_analysis;

/* ---------- Volume and ranking ---------- */

/* How many crimes occurred in each district per year? */
CREATE VIEW DISTRICT_count_year AS
SELECT district, year, COUNT(*) AS Crime_total
FROM crime_analysis
GROUP BY district, year;


/* How does each district rank against the others in the same year? */
CREATE VIEW district_count_by_year AS
SELECT
    district,
    year,
    COUNT(*) AS cnt,
    RANK() OVER (PARTITION BY year ORDER BY COUNT(*) DESC) AS rnk
FROM crime_analysis
GROUP BY district, year;


CREATE VIEW OVERVIEW_TOP_DISTICT_COUNT_BY_YEAR AS
SELECT
    district,
    COUNT(*) AS cnt,
    year,
    RANK() OVER (PARTITION BY year ORDER BY COUNT(*) DESC) AS rnks
FROM crime_analysis
GROUP BY district, year;


/* Highest- and lowest-crime district each year */
CREATE VIEW districts_highest_Crime_rate AS
WITH CTE AS (
    SELECT COUNT(case_number) AS counts, district, year,
           RANK() OVER (PARTITION BY year ORDER BY COUNT(case_number) DESC) AS rnks
    FROM crime_analysis
    GROUP BY district, year
)
SELECT district, counts, year FROM CTE WHERE rnks = 1;


CREATE OR ALTER VIEW districts_lowest_Crime_rate AS
WITH CTE AS (
    SELECT COUNT(case_number) AS counts, district, year,
           RANK() OVER (PARTITION BY year ORDER BY COUNT(case_number) ASC) AS rnks
    FROM crime_analysis
    GROUP BY district, year
)
SELECT district, counts, year FROM CTE WHERE rnks = 1;


/* Running total of crimes per district over time */
CREATE VIEW DISTRICT_Cumulative_Growth AS
SELECT
    year,
    District,
    COUNT(*) AS yearly_count,
    SUM(COUNT(*)) OVER (PARTITION BY District ORDER BY year
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sum
FROM crime_analysis
GROUP BY year, District;


/* Month-over-month crime trend per district */
CREATE VIEW DISTRICT_MONTH_OVER_MONTH_CRIME AS
WITH CTE AS (
    SELECT
        DATEPART(MONTH, Date) AS months,
        COUNT(*) AS cnt,
        DISTRICT,
        YEAR
    FROM crime_analysis
    GROUP BY DATEPART(MONTH, Date), DISTRICT, YEAR
)
SELECT
    DISTRICT,
    months,
    year,
    cnt,
    COALESCE(
        (cnt - LAG(cnt) OVER (PARTITION BY DISTRICT ORDER BY year, months)) * 100.0
        / LAG(cnt) OVER (PARTITION BY DISTRICT ORDER BY year, months), 0) AS M_O_M
FROM CTE;


/* How does each district compare to the citywide average? */
ALTER VIEW DISTRICT_CRIME_COUNT_COMPARE_TO_AVG AS
WITH crime_total AS (
    SELECT district, COUNT(*) AS crime_count
    FROM crime_analysis
    GROUP BY district
),
city_avg AS (
    SELECT AVG(crime_count * 1.0) AS average_city
    FROM crime_total
)
SELECT
    ct.district,
    ct.crime_count,
    ROUND(ca.average_city, 2) AS city_avg,
    ROUND(ct.crime_count - ca.average_city, 2) AS difference_from_avg,
    CASE
        WHEN ct.crime_count > ca.average_city THEN 'Above Average'
        WHEN ct.crime_count < ca.average_city THEN 'Below Average'
        ELSE 'At Average'
    END AS comparison
FROM crime_total ct
CROSS JOIN city_avg ca;


/* ---------- Crime types per district ---------- */

/* Top 5 crime types per district per year */
CREATE VIEW DISTRICT_NEW_TOP_10_PRIMARY_TYPE_PER_DISTRICT AS
WITH CTE AS (
    SELECT Primary_Type, district, year, COUNT(*) AS cnt,
           RANK() OVER (PARTITION BY district, year ORDER BY COUNT(*) DESC) AS rnks
    FROM crime_analysis
    GROUP BY district, year, Primary_Type
)
SELECT primary_type, district, year, cnt
FROM CTE
WHERE rnks <= 5;


/* ---------- Arrest and domestic rates per district ---------- */

CREATE VIEW DISTRICT_ARREST_RATE AS
SELECT
    year,
    district,
    COUNT(CASE WHEN arrest = 1 THEN 1 END) AS total_arrests,
    COUNT(*) AS total_crimes
FROM crime_analysis
GROUP BY year, district;


/* Which districts have an arrest rate above the citywide average? */
CREATE VIEW districts_arrest_rate_above_city_avg AS
WITH city AS (
    SELECT year, AVG(CAST(arrest AS FLOAT)) * 100 AS city_arrest_rate
    FROM crime_analysis
    GROUP BY year
),
dist AS (
    SELECT year, district, AVG(CAST(arrest AS FLOAT)) * 100 AS district_arrest_rate
    FROM crime_analysis
    GROUP BY year, district
)
SELECT d.year, d.district,
       ROUND(d.district_arrest_rate, 2) AS district_arrest_rate,
       ROUND(c.city_arrest_rate, 2)     AS city_arrest_rate
FROM dist d
JOIN city c ON c.year = d.year
WHERE d.district_arrest_rate > c.city_arrest_rate;


CREATE VIEW DISTRICT_DOMESTIC_RATE AS
SELECT
    year,
    district,
    COUNT(CASE WHEN domestic = 1 THEN 1 END) AS total_domestic,
    COUNT(*) AS total_crimes
FROM crime_analysis
GROUP BY year, district;


/* ---------- Time of day per district ---------- */

CREATE VIEW DISTRICT_HOURS_CRIME AS
SELECT
    FORMAT(DATEADD(HOUR, DATEPART(HOUR, Date), 0), 'h:00 tt') AS hour_label,
    DATEPART(HOUR, Date) AS hr_sort,
    DATEPART(YEAR, Date) AS years,
    COUNT(*) AS cnt,
    District
FROM crime_analysis
GROUP BY DATEPART(HOUR, Date), District, DATEPART(YEAR, Date);


/* ---------- Map ---------- */

CREATE VIEW map_distict AS
SELECT district, COUNT(*) AS cnt, year
FROM crime_analysis
GROUP BY district, year;


CREATE VIEW long_lat_year AS
SELECT latitude, longitude, year,
       ROW_NUMBER() OVER (ORDER BY year) AS row_id   -- unique ID so Power BI plots every point
FROM crime_analysis;

