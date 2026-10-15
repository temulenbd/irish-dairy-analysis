# SQL: the `dairy` database

This folder holds the SQL scripts for the `dairy` database in SQL Server. The database stores the clean monthly dairy data from `notebook 1`, so it can be queried with SQL and connected to Power BI.

## Files

The scripts are numbered in the order they are run.

| File | What it does |
|---|---|
| `00_create_database.sql` | Creates the `dairy` database |
| `01_create_tables.sql` | Creates the three tables: `dim_date`, `dim_measure` and `fact_monthly` |

The tables are filled from Python in `notebooks/2_sql_database.ipynb`.

The scripts are written in T-SQL (Microsoft SQL Server) and were run in SQL Server Management Studio (SSMS).

## Database design

The database uses a star schema: one fact table with the numbers, linked to two dimension tables that describe them.

```mermaid
erDiagram
    dim_date ||--o{ fact_monthly : "date_key"
    dim_measure ||--o{ fact_monthly : "measure_code"

    dim_date {
        DATE date_key PK
        INT year
        INT month
        VARCHAR month_name
        INT quarter
        VARCHAR quota_period
    }

    fact_monthly {
        DATE date_key PK, FK
        VARCHAR measure_code PK, FK
        DECIMAL value
    }

    dim_measure {
        VARCHAR measure_code PK
        VARCHAR measure_name
        VARCHAR unit
        VARCHAR country
        VARCHAR source
    }
```

- `fact_monthly` holds the numbers: one row per month and measure.
- `dim_date` describes each month: year, month, quarter and quota period.
- `dim_measure` describes each measure: name, unit, country and source table.