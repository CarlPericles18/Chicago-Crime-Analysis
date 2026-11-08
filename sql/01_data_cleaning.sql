/* ============================================================
   Chicago Crime Analysis: data cleaning
   SQL Server (SSMS)
   Table: crime_analysis  (City of Chicago "Crimes - 2001 to Present")
   ============================================================ */

-- Preview the raw data
SELECT TOP 1000 * FROM crime_analysis;

-- 1. Standardize crime type naming
UPDATE crime_analysis
SET Primary_Type = 'NARCOTIC VIOLATION'
WHERE Primary_Type = 'NARCOTICS';

-- 2. Remove duplicate records (keep the first row per case number)
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Case_Number ORDER BY ID) AS rn
    FROM crime_analysis
)
DELETE FROM CTE
WHERE rn > 1;

-- 3. Flag missing coordinates
UPDATE crime_analysis
SET Longitude = 'Unknown'
WHERE Longitude IS NULL;

-- 4. Drop unused column
ALTER TABLE crime_analysis
DROP COLUMN Beat0;

-- Check results
SELECT TOP 1000 * FROM crime_analysis;
