# Data dictionary

`data/processed/ireland_dairy_monthly.csv`: one row per month, January 1975 - August 2026 (620 months).

| Column | Unit | Description | Source | Coverage |
|---|---|---|---|---|
| `date` | | First day of the month | | |
| `intake_ml` | million litres | Domestic milk intake by processors and co-ops | AKM01 | Jan 1975 - Aug 2026, complete |
| `fat_pct` | % | Fat content of domestic intake | AKM01 | From Jan 1980 |
| `protein_pct` | % | Protein content of domestic intake | AKM01 | From Jan 1980 |
| `liquid_sales_ml` | million litres | Milk sales for human consumption, all milk | AKM02 | From Jan 1980 |
| `butter_kt` | thousand tonnes | Butter production | AKM03 | From Jan 1980 |
| `cheese_kt` | thousand tonnes | Cheese production | AKM03 | Jan 1980 - Dec 2025 |
| `smp_kt` | thousand tonnes | Skimmed milk powder production | AKM03 | From Jan 1980, 40 months missing |

`data/processed/canada_milk_monthly.csv`: `canada_total_ml`, total milk sold off farms in Canada (million litres), January 1976 - June 2026 (606 months).

`data/processed/forecast_mape_by_year.csv`: written by notebook 4, read by Power BI. Columns `year`, `model`, `mape_pct`, `test` (Backtest or Hold-out); 30 rows (10 years × 3 models).

The SQL Server database `dairy` stores the same Irish and Canadian data in a star schema (`dim_date`, `dim_measure`, `fact_monthly`). See [`sql/README.md`](../sql/README.md).
