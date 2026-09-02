-- ============================================================
-- GOLD LAYER - Complete Star Schema
-- Two Fact Tables: fact_online_sales + fact_pos_sales
-- Shared Conformed Dimensions (Galaxy Schema)
-- ============================================================

USE DataWarehouse;
GO

-- ============================================================
-- DROP EXISTING GOLD TABLES (clean start)
-- ============================================================
IF OBJECT_ID('gold.fact_online_sales','U') IS NOT NULL DROP TABLE gold.fact_online_sales;
IF OBJECT_ID('gold.fact_pos_sales','U')    IS NOT NULL DROP TABLE gold.fact_pos_sales;
GO
IF OBJECT_ID('gold.dim_delivery_provider','U') IS NOT NULL DROP TABLE gold.dim_delivery_provider;
IF OBJECT_ID('gold.dim_warehouse','U')         IS NOT NULL DROP TABLE gold.dim_warehouse;
IF OBJECT_ID('gold.dim_employee','U')          IS NOT NULL DROP TABLE gold.dim_employee;
IF OBJECT_ID('gold.dim_store','U')             IS NOT NULL DROP TABLE gold.dim_store;
IF OBJECT_ID('gold.dim_promotion','U')         IS NOT NULL DROP TABLE gold.dim_promotion;
IF OBJECT_ID('gold.dim_product','U')           IS NOT NULL DROP TABLE gold.dim_product;
IF OBJECT_ID('gold.dim_customer','U')          IS NOT NULL DROP TABLE gold.dim_customer;
IF OBJECT_ID('gold.dim_date','U')              IS NOT NULL DROP TABLE gold.dim_date;
GO

-- ============================================================
-- 1. dim_date
-- ============================================================
CREATE TABLE gold.dim_date (
    date_key        INT          NOT NULL,
    full_date       DATE         NOT NULL,
    day_of_week     TINYINT      NOT NULL,
    day_name        NVARCHAR(10) NOT NULL,
    day_of_month    TINYINT      NOT NULL,
    day_of_year     SMALLINT     NOT NULL,
    week_of_year    TINYINT      NOT NULL,
    month_number    TINYINT      NOT NULL,
    month_name      NVARCHAR(10) NOT NULL,
    quarter         TINYINT      NOT NULL,
    year            SMALLINT     NOT NULL,
    is_weekend      BIT          NOT NULL,
    CONSTRAINT PK_dim_date PRIMARY KEY (date_key)
);
GO

-- Unknown date row
INSERT INTO gold.dim_date VALUES (19000101,'1900-01-01',1,'Unknown',1,1,1,1,'Unknown',1,1900,0);
GO

-- Populate 2020-2030
WITH dates AS (
    SELECT CAST('2020-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY,1,d) FROM dates WHERE d < '2030-12-31'
)
INSERT INTO gold.dim_date (
    date_key, full_date, day_of_week, day_name, day_of_month,
    day_of_year, week_of_year, month_number, month_name,
    quarter, year, is_weekend
)
SELECT
    CONVERT(INT, FORMAT(d,'yyyyMMdd')),
    d,
    DATEPART(WEEKDAY,d),
    DATENAME(WEEKDAY,d),
    DAY(d),
    DATEPART(DAYOFYEAR,d),
    DATEPART(WEEK,d),
    MONTH(d),
    DATENAME(MONTH,d),
    DATEPART(QUARTER,d),
    YEAR(d),
    CASE WHEN DATEPART(WEEKDAY,d) IN (1,7) THEN 1 ELSE 0 END
FROM dates
OPTION (MAXRECURSION 5000);
GO

-- ============================================================
-- 2. dim_customer
-- ============================================================
CREATE TABLE gold.dim_customer (
    customer_key  INT          NOT NULL IDENTITY(1,1),
    customer_id   INT          NOT NULL,
    full_name     NVARCHAR(200) NOT NULL,
    gender        NVARCHAR(20)  NOT NULL,
    city          NVARCHAR(100) NOT NULL,
    loyalty_level NVARCHAR(50)  NOT NULL,
    email         NVARCHAR(255) NOT NULL,
    CONSTRAINT PK_dim_customer PRIMARY KEY (customer_key)
);
GO

SET IDENTITY_INSERT gold.dim_customer ON;
INSERT INTO gold.dim_customer (customer_key,customer_id,full_name,gender,city,loyalty_level,email)
VALUES (-1,0,'Unknown','Unknown','Unknown','Unknown','N/A');
SET IDENTITY_INSERT gold.dim_customer OFF;
GO

INSERT INTO gold.dim_customer (customer_id,full_name,gender,city,loyalty_level,email)
SELECT
    TRY_CAST(Customer_ID AS INT),
    TRIM(ISNULL(First_Name,'')) + ' ' + TRIM(ISNULL(Last_Name,'')),
    CASE
        WHEN UPPER(TRIM(ISNULL(Gender,''))) IN ('M','MALE')   THEN 'Male'
        WHEN UPPER(TRIM(ISNULL(Gender,''))) IN ('F','FEMALE') THEN 'Female'
        ELSE 'Unknown'
    END,
    TRIM(ISNULL(City,'Unknown')),
    TRIM(ISNULL(Loyalty_Level,'Standard')),
    LOWER(TRIM(ISNULL(Email,'N/A')))
FROM silver.CUSTOMERS;
GO

-- ============================================================
-- 3. dim_product
-- ============================================================
CREATE TABLE gold.dim_product (
    product_key     INT           NOT NULL IDENTITY(1,1),
    product_id      INT           NOT NULL,
    sku             NVARCHAR(100) NOT NULL,
    product_name    NVARCHAR(255) NOT NULL,
    brand_name      NVARCHAR(100) NOT NULL,
    department_name NVARCHAR(100) NOT NULL,
    package_size    NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_dim_product PRIMARY KEY (product_key)
);
GO

SET IDENTITY_INSERT gold.dim_product ON;
INSERT INTO gold.dim_product (product_key,product_id,sku,product_name,brand_name,department_name,package_size)
VALUES (-1,0,'N/A','Unknown','Unknown','Unknown','N/A');
SET IDENTITY_INSERT gold.dim_product OFF;
GO

INSERT INTO gold.dim_product (product_id,sku,product_name,brand_name,department_name,package_size)
SELECT
    p.Product_ID,
    TRIM(ISNULL(p.SKU,'N/A')),
    TRIM(ISNULL(p.Product_Name,'Unknown')),
    TRIM(ISNULL(b.Brand_Name,'Unknown')),
    TRIM(ISNULL(d.Department_Name,'Unknown')),
    TRIM(ISNULL(p.Package_Size,'N/A'))
FROM silver.PRODUCTS p
LEFT JOIN silver.BRANDS     b ON p.Brand_ID     = b.Brand_ID
LEFT JOIN silver.DEPARTMENTS d ON p.Department_ID = d.Department_ID;
GO

-- ============================================================
-- 4. dim_promotion
-- ============================================================
CREATE TABLE gold.dim_promotion (
    promotion_key    INT           NOT NULL IDENTITY(1,1),
    promotion_id     INT           NOT NULL,
    promo_type       NVARCHAR(255) NOT NULL,
    discount_percent DECIMAL(5,2)  NOT NULL,
    start_date       DATE          NULL,
    end_date         DATE          NULL,
    CONSTRAINT PK_dim_promotion PRIMARY KEY (promotion_key)
);
GO

SET IDENTITY_INSERT gold.dim_promotion ON;
INSERT INTO gold.dim_promotion (promotion_key,promotion_id,promo_type,discount_percent,start_date,end_date)
VALUES (-1,0,'No Promotion',0.00,NULL,NULL);
SET IDENTITY_INSERT gold.dim_promotion OFF;
GO

INSERT INTO gold.dim_promotion (promotion_id,promo_type,discount_percent,start_date,end_date)
SELECT
    Promotion_ID,
    TRIM(ISNULL(Promo_Type,'Unknown')),
    ISNULL(Discount_Percent,0.00),
    Start_Date,
    End_Date
FROM silver.PROMOTIONS;
GO

-- ============================================================
-- 5. dim_store
-- ============================================================
CREATE TABLE gold.dim_store (
    store_key    INT           NOT NULL IDENTITY(1,1),
    store_id     INT           NOT NULL,
    store_name   NVARCHAR(255) NOT NULL,
    city         NVARCHAR(100) NOT NULL,
    state        NVARCHAR(100) NOT NULL,
    region       NVARCHAR(100) NOT NULL,
    opening_date DATE          NULL,
    CONSTRAINT PK_dim_store PRIMARY KEY (store_key)
);
GO

SET IDENTITY_INSERT gold.dim_store ON;
INSERT INTO gold.dim_store (store_key,store_id,store_name,city,state,region,opening_date)
VALUES (-1,0,'Unknown Store','Unknown','Unknown','Unknown',NULL);
SET IDENTITY_INSERT gold.dim_store OFF;
GO

INSERT INTO gold.dim_store (store_id,store_name,city,state,region,opening_date)
SELECT
    Store_ID,
    TRIM(ISNULL(Store_Name,'Unknown')),
    TRIM(ISNULL(City,'Unknown')),
    TRIM(ISNULL(State,'Unknown')),
    TRIM(ISNULL(Region,'Unknown')),
    Opening_Date
FROM silver.STORES;
GO

-- ============================================================
-- 6. dim_employee
-- ============================================================
CREATE TABLE gold.dim_employee (
    employee_key  INT           NOT NULL IDENTITY(1,1),
    employee_id   INT           NOT NULL,
    full_name     NVARCHAR(200) NOT NULL,
    gender        NVARCHAR(20)  NOT NULL,
    position      NVARCHAR(100) NOT NULL,
    store_id      INT           NOT NULL,
    hire_date     DATE          NULL,
    CONSTRAINT PK_dim_employee PRIMARY KEY (employee_key)
);
GO

SET IDENTITY_INSERT gold.dim_employee ON;
INSERT INTO gold.dim_employee (employee_key,employee_id,full_name,gender,position,store_id,hire_date)
VALUES (-1,0,'Unknown Employee','Unknown','Unknown',0,NULL);
SET IDENTITY_INSERT gold.dim_employee OFF;
GO

INSERT INTO gold.dim_employee (employee_id,full_name,gender,position,store_id,hire_date)
SELECT
    Employee_ID,
    TRIM(ISNULL(Full_Name,'Unknown')),
    TRIM(ISNULL(Gender,'Unknown')),
    TRIM(ISNULL(Position,'Unknown')),
    ISNULL(Store_ID,0),
    Hire_Date
FROM silver.EMPLOYEES;
GO

-- ============================================================
-- 7. dim_warehouse
-- ============================================================
CREATE TABLE gold.dim_warehouse (
    warehouse_key  INT           NOT NULL IDENTITY(1,1),
    warehouse_id   INT           NOT NULL,
    warehouse_name NVARCHAR(200) NOT NULL,
    city           NVARCHAR(100) NOT NULL,
    state          NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_dim_warehouse PRIMARY KEY (warehouse_key)
);
GO

SET IDENTITY_INSERT gold.dim_warehouse ON;
INSERT INTO gold.dim_warehouse (warehouse_key,warehouse_id,warehouse_name,city,state)
VALUES (-1,0,'Unknown Warehouse','Unknown','Unknown');
SET IDENTITY_INSERT gold.dim_warehouse OFF;
GO

INSERT INTO gold.dim_warehouse (warehouse_id,warehouse_name,city,state)
SELECT
    Warehouse_ID,
    TRIM(ISNULL(Warehouse_Name,'Unknown')),
    TRIM(ISNULL(City,'Unknown')),
    TRIM(ISNULL(State,'Unknown'))
FROM silver.WAREHOUSES;
GO

-- ============================================================
-- 8. dim_delivery_provider
-- ============================================================
CREATE TABLE gold.dim_delivery_provider (
    delivery_provider_key INT           NOT NULL IDENTITY(1,1),
    provider_id           INT           NOT NULL,
    provider_name         NVARCHAR(200) NOT NULL,
    phone                 NVARCHAR(50)  NOT NULL,
    CONSTRAINT PK_dim_delivery_provider PRIMARY KEY (delivery_provider_key)
);
GO

SET IDENTITY_INSERT gold.dim_delivery_provider ON;
INSERT INTO gold.dim_delivery_provider (delivery_provider_key,provider_id,provider_name,phone)
VALUES (-1,0,'Unknown Provider','N/A');
SET IDENTITY_INSERT gold.dim_delivery_provider OFF;
GO

INSERT INTO gold.dim_delivery_provider (provider_id,provider_name,phone)
SELECT
    Provider_ID,
    TRIM(ISNULL(Provider_Name,'Unknown')),
    TRIM(ISNULL(Phone,'N/A'))
FROM silver.DELIVERY_PROVIDERS;
GO

-- ============================================================
-- 9. fact_pos_sales
-- Grain: one row per POS transaction line item
-- ============================================================
CREATE TABLE gold.fact_pos_sales (
    pos_sales_key    BIGINT        NOT NULL IDENTITY(1,1),
    date_key         INT           NOT NULL,
    customer_key     INT           NOT NULL,
    product_key      INT           NOT NULL,
    promotion_key    INT           NOT NULL,
    store_key        INT           NOT NULL,
    employee_key     INT           NOT NULL,
    transaction_id   NVARCHAR(50)  NOT NULL,
    quantity         INT           NOT NULL,
    unit_price       DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2)  NOT NULL DEFAULT 0,
    gross_amount     DECIMAL(12,2) NOT NULL,
    discount_amount  DECIMAL(12,2) NOT NULL,
    net_amount       DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_fact_pos_sales    PRIMARY KEY (pos_sales_key),
    CONSTRAINT FK_fps_date          FOREIGN KEY (date_key)      REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fps_customer      FOREIGN KEY (customer_key)  REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fps_product       FOREIGN KEY (product_key)   REFERENCES gold.dim_product(product_key),
    CONSTRAINT FK_fps_promotion     FOREIGN KEY (promotion_key) REFERENCES gold.dim_promotion(promotion_key),
    CONSTRAINT FK_fps_store         FOREIGN KEY (store_key)     REFERENCES gold.dim_store(store_key),
    CONSTRAINT FK_fps_employee      FOREIGN KEY (employee_key)  REFERENCES gold.dim_employee(employee_key)
);
GO

INSERT INTO gold.fact_pos_sales (
    date_key, customer_key, product_key, promotion_key,
    store_key, employee_key, transaction_id,
    quantity, unit_price, discount_percent,
    gross_amount, discount_amount, net_amount
)
SELECT
    ISNULL(dd.date_key, 19000101)                           AS date_key,
    ISNULL(dc.customer_key, -1)                            AS customer_key,
    ISNULL(dp.product_key, -1)                             AS product_key,
    ISNULL(dpr.promotion_key, -1)                          AS promotion_key,
    ISNULL(ds.store_key, -1)                               AS store_key,
    ISNULL(de.employee_key, -1)                            AS employee_key,
    TRIM(ti.Transaction_ID)                                AS transaction_id,
    ISNULL(ti.Quantity, 0)                                 AS quantity,
    ISNULL(ti.Unit_Price, 0.00)                            AS unit_price,
    ISNULL(dpr.discount_percent, 0.00)                     AS discount_percent,
    ISNULL(ti.Quantity,0) * ISNULL(ti.Unit_Price,0.00)     AS gross_amount,
    ISNULL(ti.Quantity,0) * ISNULL(ti.Unit_Price,0.00)
        * ISNULL(dpr.discount_percent,0.00) / 100          AS discount_amount,
    ISNULL(ti.Quantity,0) * ISNULL(ti.Unit_Price,0.00)
        * (1 - ISNULL(dpr.discount_percent,0.00) / 100)   AS net_amount
FROM silver.TRANSACTION_ITEMS ti
LEFT JOIN silver.POS_TRANSACTIONS t
    ON ti.Transaction_ID = t.Transaction_ID
LEFT JOIN gold.dim_date dd
    ON dd.full_date = t.Transaction_Date
LEFT JOIN gold.dim_customer dc
    ON t.Customer_ID = dc.customer_id
LEFT JOIN gold.dim_product dp
    ON ti.Product_ID = dp.product_id
LEFT JOIN gold.dim_promotion dpr
    ON ti.Promotion_ID = dpr.promotion_id
LEFT JOIN gold.dim_store ds
    ON t.Store_ID = ds.store_id
LEFT JOIN gold.dim_employee de
    ON t.Employee_ID = de.employee_id;
GO

-- ============================================================
-- 10. fact_online_sales
-- Grain: one row per online order line item
-- ============================================================
CREATE TABLE gold.fact_online_sales (
    online_sales_key      BIGINT        NOT NULL IDENTITY(1,1),
    order_date_key        INT           NOT NULL,
    delivery_date_key     INT           NOT NULL,
    customer_key          INT           NOT NULL,
    product_key           INT           NOT NULL,
    promotion_key         INT           NOT NULL,
    warehouse_key         INT           NOT NULL,
    delivery_provider_key INT           NOT NULL,
    order_id              INT           NOT NULL,
    order_status          NVARCHAR(100) NOT NULL,
    delivery_status       NVARCHAR(100) NOT NULL,
    payment_method        NVARCHAR(100) NOT NULL,
    quantity              INT           NOT NULL,
    unit_price            DECIMAL(10,2) NOT NULL,
    discount_percent      DECIMAL(5,2)  NOT NULL DEFAULT 0,
    gross_amount          DECIMAL(12,2) NOT NULL,
    discount_amount       DECIMAL(12,2) NOT NULL,
    net_amount            DECIMAL(12,2) NOT NULL,
    delivery_days         INT           NULL,
    CONSTRAINT PK_fact_online_sales       PRIMARY KEY (online_sales_key),
    CONSTRAINT FK_fos_order_date          FOREIGN KEY (order_date_key)        REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fos_delivery_date       FOREIGN KEY (delivery_date_key)     REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fos_customer            FOREIGN KEY (customer_key)          REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fos_product             FOREIGN KEY (product_key)           REFERENCES gold.dim_product(product_key),
    CONSTRAINT FK_fos_promotion           FOREIGN KEY (promotion_key)         REFERENCES gold.dim_promotion(promotion_key),
    CONSTRAINT FK_fos_warehouse           FOREIGN KEY (warehouse_key)         REFERENCES gold.dim_warehouse(warehouse_key),
    CONSTRAINT FK_fos_delivery_provider   FOREIGN KEY (delivery_provider_key) REFERENCES gold.dim_delivery_provider(delivery_provider_key)
);
GO

INSERT INTO gold.fact_online_sales (
    order_date_key, delivery_date_key,
    customer_key, product_key, promotion_key,
    warehouse_key, delivery_provider_key,
    order_id, order_status, delivery_status, payment_method,
    quantity, unit_price, discount_percent,
    gross_amount, discount_amount, net_amount, delivery_days
)
SELECT
    ISNULL(od.date_key, 19000101)                               AS order_date_key,
    ISNULL(deliv_d.date_key, 19000101)                         AS delivery_date_key,
    ISNULL(dc.customer_key, -1)                                AS customer_key,
    ISNULL(dp.product_key, -1)                                 AS product_key,
    ISNULL(dpr.promotion_key, -1)                              AS promotion_key,
    ISNULL(dw.warehouse_key, -1)                               AS warehouse_key,
    ISNULL(ddp.delivery_provider_key, -1)                      AS delivery_provider_key,
    o.Order_ID                                                  AS order_id,
    TRIM(ISNULL(o.Order_Status,'Unknown'))                     AS order_status,
    TRIM(ISNULL(d.Delivery_Status,'Unknown'))                  AS delivery_status,
    TRIM(ISNULL(pay.Payment_Method,'Unknown'))                 AS payment_method,
    ISNULL(oi.Quantity,0)                                      AS quantity,
    ISNULL(oi.Unit_Price,0.00)                                 AS unit_price,
    ISNULL(dpr.discount_percent,0.00)                          AS discount_percent,
    ISNULL(oi.Quantity,0) * ISNULL(oi.Unit_Price,0.00)         AS gross_amount,
    ISNULL(oi.Quantity,0) * ISNULL(oi.Unit_Price,0.00)
        * ISNULL(dpr.discount_percent,0.00) / 100              AS discount_amount,
    ISNULL(oi.Quantity,0) * ISNULL(oi.Unit_Price,0.00)
        * (1 - ISNULL(dpr.discount_percent,0.00) / 100)       AS net_amount,
    d.Delivery_Days                                             AS delivery_days
FROM silver.ONLINE_ORDER_ITEMS oi
JOIN  silver.ONLINE_ORDERS o      ON oi.Order_ID    = o.Order_ID
LEFT JOIN silver.DELIVERIES d     ON o.Order_ID     = d.Order_ID
LEFT JOIN (
    SELECT Order_ID, Payment_Method,
           ROW_NUMBER() OVER (PARTITION BY Order_ID ORDER BY Payment_ID) AS rn
    FROM silver.PAYMENTS
) pay ON o.Order_ID = pay.Order_ID AND pay.rn = 1
LEFT JOIN gold.dim_date od          ON od.full_date    = o.Order_Date
LEFT JOIN gold.dim_date deliv_d     ON deliv_d.full_date = d.Delivery_Date
LEFT JOIN gold.dim_customer dc      ON o.Customer_ID   = dc.customer_id
LEFT JOIN gold.dim_product dp       ON oi.Product_ID   = dp.product_id
LEFT JOIN gold.dim_promotion dpr    ON oi.Promotion_ID = dpr.promotion_id
LEFT JOIN gold.dim_warehouse dw     ON o.Warehouse_ID  = dw.warehouse_id
LEFT JOIN gold.dim_delivery_provider ddp ON d.Provider_ID = ddp.provider_id;
GO

-- ============================================================
-- VALIDATION
-- ============================================================
SELECT 'dim_date'              AS table_name, COUNT(*) AS row_count FROM gold.dim_date              UNION ALL
SELECT 'dim_customer',                        COUNT(*)              FROM gold.dim_customer           UNION ALL
SELECT 'dim_product',                         COUNT(*)              FROM gold.dim_product            UNION ALL
SELECT 'dim_promotion',                       COUNT(*)              FROM gold.dim_promotion          UNION ALL
SELECT 'dim_store',                           COUNT(*)              FROM gold.dim_store              UNION ALL
SELECT 'dim_employee',                        COUNT(*)              FROM gold.dim_employee           UNION ALL
SELECT 'dim_warehouse',                       COUNT(*)              FROM gold.dim_warehouse          UNION ALL
SELECT 'dim_delivery_provider',               COUNT(*)              FROM gold.dim_delivery_provider  UNION ALL
SELECT 'fact_pos_sales',                      COUNT(*)              FROM gold.fact_pos_sales         UNION ALL
SELECT 'fact_online_sales',                   COUNT(*)              FROM gold.fact_online_sales;
GO

PRINT 'Gold Layer loaded successfully';
GO
