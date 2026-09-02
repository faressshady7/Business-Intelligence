/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates the staging tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
      Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

USE DataWarehouse;
GO

-- ===================== CRM TABLES =====================

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

-- ===================== ERP TABLES =====================

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

-- ===================== WEB TABLES =====================

IF OBJECT_ID('bronze.web_sessions', 'U') IS NOT NULL
    DROP TABLE bronze.web_sessions;

IF OBJECT_ID('bronze.web_events', 'U') IS NOT NULL
    DROP TABLE bronze.web_events;

IF OBJECT_ID('bronze.web_conversions', 'U') IS NOT NULL
    DROP TABLE bronze.web_conversions;

-- ===================== LOG TABLE =====================

IF OBJECT_ID('bronze.load_log', 'U') IS NOT NULL
    DROP TABLE bronze.load_log;
GO

-- ===================== CREATE CRM TABLES =====================

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);

-- ===================== CREATE ERP TABLES =====================

CREATE TABLE bronze.erp_loc_a101 (
    cid    NVARCHAR(50),
    cntry  NVARCHAR(50)
);

CREATE TABLE bronze.erp_cust_az12 (
    cid    NVARCHAR(50),
    bdate  DATE,
    gen    NVARCHAR(50)
);

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           NVARCHAR(50),
    cat          NVARCHAR(50),
    subcat       NVARCHAR(50),
    maintenance  NVARCHAR(50)
);

-- ===================== CREATE WEB TABLES =====================

CREATE TABLE bronze.web_sessions (
    session_id      NVARCHAR(50),
    customer_id     INT,
    session_start   DATETIME,
    session_end     DATETIME,
    device_type     NVARCHAR(50),
    traffic_source  NVARCHAR(50),
    country         NVARCHAR(50)
);

CREATE TABLE bronze.web_events (
    event_id        INT,
    session_id      NVARCHAR(50),
    customer_id     INT,
    event_type      NVARCHAR(50),
    product_key     NVARCHAR(50),
    event_timestamp DATETIME
);

CREATE TABLE bronze.web_conversions (
    conversion_id        INT,
    session_id           NVARCHAR(50),
    order_number         NVARCHAR(50),
    conversion_timestamp DATETIME,
    revenue              DECIMAL(18,2)
);

-- ===================== CREATE LOG TABLE =====================

CREATE TABLE bronze.load_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    procedure_name NVARCHAR(200),
    table_name NVARCHAR(200),
    load_start_time DATETIME,
    load_end_time DATETIME,
    duration_seconds INT,
    rows_inserted INT,
    status NVARCHAR(20),
    error_message NVARCHAR(MAX)
);
GO
