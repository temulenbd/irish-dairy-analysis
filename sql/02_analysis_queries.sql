/*
    02_analysis_queries.sql
    Analysis queries on the dairy database.

    Each query answers one question about Irish milk supply.
    Run 00_create_database.sql, 01_create_tables.sql and
    notebook 2 first, so the tables hold data.
*/

USE dairy;

/*
    Query 1: Total milk intake per year

    Sums the monthly milk intake for each year.
    Only complete years (12 months) are kept, so a part year
    such as 2026 does not look like a fall in supply.
*/
SELECT
    d.[year],
    SUM(f.value) AS total_intake_ml,    -- million litres
    COUNT(*)     AS n_months            -- months with a value
FROM fact_monthly AS f
JOIN dim_date AS d
    ON f.date_key = d.date_key          -- link each value to its month
WHERE f.measure_code = 'intake_ml'      -- milk intake only
GROUP BY d.[year]
HAVING COUNT(*) = 12                    -- complete years only
ORDER BY d.[year];


/*
    Query 2: Year-on-year change in milk intake

    Compares each year's total with the year before, in million
    litres and in percent. The yearly totals come from the same
    logic as Query 1, written as a CTE (WITH ... AS) so they can
    be reused. Only complete years are used.
*/
WITH yearly AS (                            -- step 1: total per complete year
    SELECT
        d.[year],
        SUM(f.value) AS total_intake_ml
    FROM fact_monthly AS f
    JOIN dim_date AS d
        ON f.date_key = d.date_key
    WHERE f.measure_code = 'intake_ml'
    GROUP BY d.[year]
    HAVING COUNT(*) = 12
),
with_previous AS (                          -- step 2: add the previous year's total
    SELECT
        [year],
        total_intake_ml,
        LAG(total_intake_ml) OVER (ORDER BY [year]) AS previous_year_ml
    FROM yearly
)
SELECT                                      -- step 3: calculate the change
    [year],
    total_intake_ml,
    previous_year_ml,
    total_intake_ml - previous_year_ml AS change_ml,
    CAST(100.0 * (total_intake_ml - previous_year_ml) / previous_year_ml
         AS DECIMAL(5, 1)) AS change_pct
FROM with_previous
ORDER BY [year];

/*
    Query 3: Average milk intake by calendar month, 2016 to 2025

    Shows the seasonal pattern of Irish milk supply.
    Uses the last ten complete years, so the averages reflect
    current supply levels and every month has the same number
    of years.
*/
SELECT
    d.[month],
    d.month_name,
    CAST(AVG(f.value) AS DECIMAL(7, 1)) AS avg_intake_ml,   -- million litres
    COUNT(*)                            AS n_years
FROM fact_monthly AS f
JOIN dim_date AS d
    ON f.date_key = d.date_key
WHERE f.measure_code = 'intake_ml'
  AND d.[year] BETWEEN 2016 AND 2025                         -- last ten complete years
GROUP BY d.[month], d.month_name
ORDER BY d.[month];

/*
    Query 4: Average yearly milk intake in each quota period

    Compares supply before quotas (to March 1984), under quotas
    (April 1984 to March 2015) and after quotas (from April 2015).
    Step 1 totals each complete year inside a period. 1984 and 2015
    are split between two periods, so they are not complete in
    either and are left out. Step 2 averages the yearly totals.
*/
WITH yearly AS (                            -- step 1: total per complete year in each period
    SELECT
        d.quota_period,
        d.[year],
        SUM(f.value) AS total_intake_ml
    FROM fact_monthly AS f
    JOIN dim_date AS d
        ON f.date_key = d.date_key
    WHERE f.measure_code = 'intake_ml'
    GROUP BY d.quota_period, d.[year]
    HAVING COUNT(*) = 12
)
SELECT                                      -- step 2: average per period
    quota_period,
    COUNT(*)                                     AS n_years,
    MIN([year])                                  AS first_year,
    MAX([year])                                  AS last_year,
    CAST(AVG(total_intake_ml) AS DECIMAL(7, 1))  AS avg_yearly_intake_ml
FROM yearly
GROUP BY quota_period
ORDER BY first_year;

/*
    Query 5: Ireland vs Canada, average milk by calendar month

    Compares the seasonal pattern of the two countries over the
    same ten complete years (2016 to 2025). Each CTE is the same
    as Query 3 for one country. The two are joined on the month
    number, so each row shows one month for both countries.
*/
WITH ireland AS (                           -- Ireland: average per calendar month
    SELECT
        d.[month],
        d.month_name,
        AVG(f.value) AS avg_ml
    FROM fact_monthly AS f
    JOIN dim_date AS d
        ON f.date_key = d.date_key
    WHERE f.measure_code = 'intake_ml'
      AND d.[year] BETWEEN 2016 AND 2025
    GROUP BY d.[month], d.month_name
),
canada AS (                                 -- Canada: average per calendar month
    SELECT
        d.[month],
        AVG(f.value) AS avg_ml
    FROM fact_monthly AS f
    JOIN dim_date AS d
        ON f.date_key = d.date_key
    WHERE f.measure_code = 'canada_total_ml'
      AND d.[year] BETWEEN 2016 AND 2025
    GROUP BY d.[month]
)
SELECT
    i.[month],
    i.month_name,
    CAST(i.avg_ml AS DECIMAL(7, 1)) AS ireland_avg_ml,    -- million litres
    CAST(c.avg_ml AS DECIMAL(7, 1)) AS canada_avg_ml      -- million litres
FROM ireland AS i
JOIN canada AS c
    ON i.[month] = c.[month]                -- match the same calendar month
ORDER BY i.[month];

/*
    Query 6: Change in milk intake and products, 2014 to 2025

    Compares the last full year under quotas (2014) with the latest
    complete year (2025) for milk intake, liquid milk sales, butter
    and cheese. Step 1 totals each measure for the two years and
    keeps only complete years. Step 2 uses the yearly table twice,
    once for each year, so each row shows both totals of one measure.
    The units differ (million litres and thousand tonnes), so the
    measures are compared by percent change.
*/
WITH yearly AS (                            -- step 1: yearly total per measure
    SELECT
        f.measure_code,
        d.[year],
        SUM(f.value) AS total
    FROM fact_monthly AS f
    JOIN dim_date AS d
        ON f.date_key = d.date_key
    WHERE f.measure_code IN ('intake_ml', 'liquid_sales_ml', 'butter_kt', 'cheese_kt')
      AND d.[year] IN (2014, 2025)          -- IN: any value in the list
    GROUP BY f.measure_code, d.[year]
    HAVING COUNT(*) = 12                    -- complete years only
)
SELECT                                      -- step 2: both years side by side
    m.measure_name,
    m.unit,
    s.total AS total_2014,
    e.total AS total_2025,
    CAST(100.0 * (e.total - s.total) / s.total AS DECIMAL(5, 1)) AS change_pct
FROM yearly AS s                            -- s = start year
JOIN yearly AS e                            -- e = end year
    ON s.measure_code = e.measure_code      -- same measure in both
JOIN dim_measure AS m
    ON s.measure_code = m.measure_code      -- name and unit of the measure
WHERE s.[year] = 2014
  AND e.[year] = 2025
ORDER BY change_pct DESC;

/*
    Query 7: Yearly fat content of milk, weighted by intake

    A simple average of the 12 monthly fat values gives January the
    same weight as May, although May has about six times as much
    milk. The weighted average multiplies each month's fat content
    by its intake, sums this over the year and divides by the
    yearly intake.

    fact_monthly is used twice: once for the intake rows (alias i)
    and once for the fat rows (alias f), joined on the month. The
    simple average is shown next to the weighted one for comparison.
*/
SELECT
    d.[year],
    CAST(SUM(i.value * f.value) / SUM(i.value) AS DECIMAL(4, 2)) AS fat_weighted_pct,
    CAST(AVG(f.value) AS DECIMAL(4, 2))                          AS fat_simple_avg_pct,
    COUNT(*)                                                     AS n_months
FROM fact_monthly AS i                      -- i = intake rows
JOIN fact_monthly AS f                      -- f = fat rows
    ON i.date_key = f.date_key              -- same month
JOIN dim_date AS d
    ON i.date_key = d.date_key
WHERE i.measure_code = 'intake_ml'
  AND f.measure_code = 'fat_pct'
GROUP BY d.[year]
HAVING COUNT(*) = 12                        -- complete years only
ORDER BY d.[year];