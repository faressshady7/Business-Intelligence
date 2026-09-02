# Enterprise Retail Data Warehouse & BI Analytics Architecture

This repository contains an end-to-end Enterprise Data Warehouse (EDW) implementation built using Microsoft SQL Server and Power BI. The project follows a modern Medallion Architecture (Bronze, Silver, and Gold layers) to extract, cleanse, transform, and model raw operational retail data (OLTP) into a high-performance Galaxy Star Schema tailored for business intelligence and reporting.

---


### 1. Source / Bronze Layer (Raw Landing)
* **Purpose**: Serves as the initial landing zone for raw operational data extracted directly from the OLTP source.
* **Features**: Preserves original row structures, null values, and raw datatypes for full auditability and line-of-sight data lineage.
* **Entities (19 Tables)**: `CUSTOMERS`, `PRODUCTS`, `BRANDS`, `DEPARTMENTS`, `POS_TRANSACTIONS`, `TRANSACTION_ITEMS`, `ONLINE_ORDERS`, `ONLINE_ORDER_ITEMS`, `PAYMENTS`, `PROMOTIONS`, `STORES`, `REGISTERS`, `EMPLOYEES`, `INVENTORY`, `WAREHOUSES`, `DELIVERIES`, `DELIVERY_PROVIDERS`, `SUPPLIERS`, `PRODUCT_SUPPLIERS`.

### 2. Silver Layer (Cleansing & Transformation)
* **Purpose**: Acts as the curated, validated reporting layer where data quality issues are addressed.
* **Transformations Applied**:
  * Text standardization (e.g., casing alignment and `TRIM` applied to string values)[cite: 1, 2].
  * Standardized gender fields (`M`/`Male` -> `Male`, `F`/`Female` -> `Female`)[cite: 1, 2].
  * Handling and flagging missing or null attributes (`Quantity`, `Unit_Price`, `Discount_Percent`).
  * Derived fields, such as concatenating customer full names (`First_Name` + `Last_Name`)[cite: 1, 2].
  * Datatype conversions for dates, timestamps, and financial amounts.
  * Integrated automated logging table (`silver.ETL_LOG`) to audit ETL loads.

### 3. Gold Layer (Dimensional Modeling - Galaxy Schema)
* **Architecture**: A multi-fact (Galaxy) Star Schema featuring conformed shared dimensions across distinct business channels.
* **Fact Tables**:
  * `gold.fact_pos_sales`: Point-of-Sale (in-store) line-item granularity.
  * `gold.fact_online_sales`: E-commerce order line-item granularity incorporating fulfillment and delivery logistics.
* **Conformed & Specific Dimensions**:
  * `gold.dim_date`: Generated calendar dimension spanning 2020–2030 with time intelligence attributes[cite: 2].
  * `gold.dim_customer`: Customer demographic and loyalty profiles[cite: 2].
  * `gold.dim_product`: Integrated hierarchy (Products, Brands, Departments)[cite: 2].
  * `gold.dim_promotion`: Marketing campaign tracking and discount rules[cite: 2].
  * `gold.dim_store` & `gold.dim_employee`: Physical retail operational network[cite: 2].
  * `gold.dim_warehouse` & `gold.dim_delivery_provider`: Supply chain & logistics[cite: 2].

---

## Technologies Used

* **Database Management**: Microsoft SQL Server (SSMS)
* **Data Modeling & ETL**: T-SQL Scripts (Schemas, DDL, Insert/Select Transformations, Dynamic Data Generation)[cite: 1, 2]
* **Data Visualization**: Power BI (DirectQuery / Import, DAX Time Intelligence, Star Schema Modeling)

---

## Data Model & ERD

Below is the conceptual layout of the Gold Layer Star Schema[cite: 2]:

* **Fact Tables**: `gold.fact_pos_sales`, `gold.fact_online_sales`[cite: 2]
* **Dimensions**: `dim_date`, `dim_customer`, `dim_product`, `dim_promotion`, `dim_store`, `dim_employee`, `dim_warehouse`, `dim_delivery_provider`[cite: 2]
* **Relationships**: Multi-dimensional One-to-Many (`1:*`) relationships enforced from dimension surrogate keys to fact foreign keys[cite: 2].
