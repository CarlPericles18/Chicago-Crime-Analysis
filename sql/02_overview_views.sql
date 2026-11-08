/* ============================================================
   Chicago Crime Analysis: Overview page views
   Trend, crime type, arrest/domestic rates, time-of-day patterns
   ============================================================ */

/* Slicer: list of years */
ALTER VIEW NEW_YEARS AS
SELECT DISTINCT year FROM crime_analysis;


/* ---------- Trend analysis ---------- */

/* How has overall crime volume changed year over year? */
ALTER VIEW crime_count_by_year AS
SELECT COUNT(*) AS cnt, year
FROM crime_analysis
GROUP BY year;


ALTER VIEW crime_rate_trend_over_years AS
SELECT COUNT(DISTINCT case_number) AS crime_count, year
FROM crime_analysis
GROUP BY year;

/* Which months consistently see the highest crime? */
CREATE OR ALTER VIEW crime_rate_by_month_years AS
SELECT
    year,
    DATEPART(MONTH, Date) AS months,
    COUNT(DISTINCT Case_Number) AS counts
FROM crime_analysis
GROUP BY year, DATEPART(MONTH, Date);


/* Month-over-month % change in crime volume */
CREATE VIEW month_over_month_perc_chng_crime_vol AS
WITH CTE AS (
    SELECT
        year,
        DATEPART(MONTH, Date) AS months,
        COUNT(*) AS volume
    FROM crime_analysis
    GROUP BY year, DATEPART(MONTH, Date)
)
SELECT
    year,
    months,
    volume,
    COALESCE(
        (volume - LAG(volume) OVER (ORDER BY year, months)) * 100.0
        / LAG(volume) OVER (ORDER BY year, months), 0) AS percentage_change
FROM CTE;


/* ---------- Crime types ---------- */

/* Are certain crime types increasing or decreasing over time? */
ALTER VIEW crime_type_overtime AS
SELECT
    COUNT(DISTINCT case_number) AS counts,
    year,
    primary_type,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY COUNT(DISTINCT case_number) DESC) AS rnks
FROM crime_analysis
GROUP BY year, primary_type;


/* Top 10 most frequent crime types per year */
ALTER VIEW TOP_TEN_CRIME_TYPE AS
WITH CTE AS (
    SELECT
        COUNT(DISTINCT case_number) AS counts,
        year,
        primary_type,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY COUNT(DISTINCT case_number) DESC) AS rnks
    FROM crime_analysis
    GROUP BY year, primary_type
)
SELECT year, counts, primary_type
FROM CTE
WHERE rnks <= 10;


ALTER VIEW TOP_CRIME_BY_YEAR AS
SELECT primary_type, year, COUNT(*) AS cnt,
       RANK() OVER (PARTITION BY year ORDER BY COUNT(*) DESC) AS rnks
FROM crime_analysis
GROUP BY primary_type, year;


/* Which crime types are most likely to be domestic-related? */
CREATE VIEW CRIME_DOMESTIC_RELATED_BY_YEAR AS
SELECT
    primary_type,
    COUNT(case_number) AS cnt,
    year,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY COUNT(case_number) DESC) AS rnks
FROM crime_analysis
WHERE Domestic = 1
GROUP BY primary_type, year;


/* ---------- Arrest and domestic rates (KPI cards) ---------- */

CREATE VIEW PERCENTAGE_OF_CRIME_ARREST AS
SELECT
    year,
    COUNT(CASE WHEN arrest = 1 THEN 1 END) AS total_arrests,
    COUNT(*) AS total_crimes
FROM crime_analysis
GROUP BY year;


ALTER VIEW PERCENTAGE_OF_CRIME_DOMESTIC AS
SELECT
    year,
    COUNT(CASE WHEN domestic = 1 THEN 1 END) AS total_domestic,
    COUNT(*) AS total_crimes
FROM crime_analysis
GROUP BY year;


/* Has the arrest rate improved or declined over the years? */
ALTER VIEW crime_rate_over_time_percentage AS
SELECT
    ROUND(CAST(COUNT(CASE WHEN arrest = 1 THEN 1 END) AS FLOAT) / COUNT(*) * 100.0, 2) AS percentage_rate,
    year
FROM crime_analysis
GROUP BY year;


/* ---------- Locations ---------- */

/* Top 5 location types per year */
ALTER VIEW TOP_10_location_desc AS
WITH CTE AS (
    SELECT
        location_description,
        year,
        COUNT(*) AS cnt,
        RANK() OVER (PARTITION BY year ORDER BY COUNT(*) DESC) AS rnks
    FROM crime_analysis
    GROUP BY location_description, year
)
SELECT location_description, year, cnt
FROM CTE
WHERE rnks <= 5;


/* ---------- Time of day ---------- */

ALTER VIEW OVERVIEW_HOURS_CRIME AS
SELECT
    FORMAT(DATEADD(HOUR, DATEPART(HOUR, Date), 0), 'h:00 tt') AS hour_label,
    DATEPART(HOUR, Date) AS hr_sort,
    DATEPART(YEAR, Date) AS years,
    COUNT(*) AS cnt
FROM crime_analysis
GROUP BY DATEPART(HOUR, Date), DATEPART(YEAR, Date);

