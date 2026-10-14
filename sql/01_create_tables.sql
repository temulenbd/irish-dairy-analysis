/*
    01_create_tables.sql
    Creates the tables for the dairy database.

    The database uses a star schema:
    - fact_monthly holds the numbers (one row per month and measure)
    - dim_date describes each month (year, month, quarter, quota period)
    - dim_measure describes each measure (name, unit, country, source)
    Queries join the fact table to the two dimension tables.
*/

USE dairy;
/*
    Delete the tables if they already exist,
    so this file can be run again without errors.
*/
DROP TABLE IF EXISTS fact_monthly;
DROP TABLE IF EXISTS dim_measure;
DROP TABLE IF EXISTS dim_date;

/*
    dim_date: one row per month.
    date_key is the link to fact_monthly.
    The other columns are labels taken from the date, so queries and
    Power BI can group and filter by year, month or quarter directly.
*/
CREATE TABLE dim_date (
    date_key      DATE         NOT NULL PRIMARY KEY,  
    [year]        INT          NOT NULL,              
    [month]       INT          NOT NULL,              
    month_name    VARCHAR(10)  NOT NULL,              
    [quarter]     INT          NOT NULL,              -- 1 to 4
    quota_period  VARCHAR(20)  NOT NULL               -- pre-quota (before Apr 1984), quota (Apr 1984 – Mar 2015), post-quota (from Apr 2015)
);

/*
    dim_measure: one row per measure.
    Describes what each number in fact_monthly means: its full name,
    unit, country and the source table it comes from.
*/
CREATE TABLE dim_measure (
    measure_code  VARCHAR(30)   NOT NULL PRIMARY KEY,  
    measure_name  VARCHAR(100)  NOT NULL,              
    unit          VARCHAR(30)   NOT NULL,              -- e.g. million litres, %, thousand tonnes
    country       VARCHAR(20)   NOT NULL,              -- Ireland or Canada
    source        VARCHAR(50)   NOT NULL               
);

/*
    fact_monthly: one row per month and measure.
    Holds the actual numbers. Each row is linked to dim_date (when)
    and to dim_measure (what). Months with no value have no row.
*/
CREATE TABLE fact_monthly (
    date_key      DATE            NOT NULL REFERENCES dim_date (date_key),        
    measure_code  VARCHAR(30)     NOT NULL REFERENCES dim_measure (measure_code), -- which measure
    value         DECIMAL(12, 3)  NOT NULL,                                       
    PRIMARY KEY (date_key, measure_code)                                          -- one value per month and measure
);