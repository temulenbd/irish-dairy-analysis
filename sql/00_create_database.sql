/*
    00_create_database.sql
    Project: Irish Milk Supply: Growth, Seasonality and Forecasting
    Author:  Temuulen Bulgan

    In this file I create the empty database for the project.
    Run this file first, then 01_create_tables.sql.
*/

/* Switch to the master database, where new databases are created */
USE master;
GO

/* Create the database only if it does not exist yet */
IF DB_ID('dairy') IS NULL
    CREATE DATABASE dairy;
GO
