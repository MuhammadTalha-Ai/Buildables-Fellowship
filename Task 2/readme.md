# 📊 Mini Data Warehouse Project

This project demonstrates the design and implementation of a **mini star schema data warehouse** with dimensions and a fact table.  
It includes ETL-style inserts, Slowly Changing Dimension (SCD Type 2) handling, and analytical SQL queries with output results.

---

## 🗂 Project Structure

- **Schema Design**
  - `dim_date` – Date dimension  
  - `dim_customers` – Customer dimension (SCD Type 2)  
  - `dim_products` – Product dimension  
  - `fact_orders` – Fact table (sales orders)  

- **SQL Scripts**
  - `mini_dw.sql` → Schema creation, inserts, and queries  
  - `mini_dw_clean.sql` → Same as above with clean comments  
  - `short_writeup.md` → Half-page project reflection  

- **CSV Outputs** → Query results saved as CSV files

---

## ⚙️ Steps

### Step 1 – Create Schema & Load Data
- Created `dim_customers`, `dim_products`, `dim_date`, and `fact_orders`.
- Implemented **SCD Type 2** for customer dimension.
- Inserted sample customers, products, and sales orders.

### Step 2 – Run Analytical Queries
Queries answer business-style questions such as:
- Total revenue per product category
- Monthly revenue trends
- Top customers by spending
- Most ordered products

---

## 📈 Query Results (CSV Outputs)

Click below to view the analysis results:

1. [Total revenue per product category](./1%29%20Total%20revenue%20per%20product%20category.csv)  
2. [Monthly revenue trend](./2%29%20Monthly%20revenue%20trend.csv)  
3. [Top 3 most ordered products](./3%29%20Top%203%20most%20ordered%20products.csv)  
4. [Top 2 customers by spend per month](./4%29%20Top%202%20customers%20by%20spend%20per%20month.csv)  
5. [Customers who ordered more than 2 different products](./5%29%20Customers%20with%20more%20than%202%20products.csv)  

---

## 📝 Reflection

- **New Learning:** How to use constraints (`CHECK`, `FOREIGN KEY`), SCD Type 2 handling, and window functions (`RANK`, `SUM OVER`) in SQL.  
- **Challenge:** Designing queries with cumulative/rank logic using CTEs and window functions.  
- **Outcome:** Built a working mini data warehouse with business insights.

---

## 🚀 How to Run
1. Clone the repo  
2. Run `Mini_dw_e-commerce.sql` in PostgreSQL  
3. Export query results to CSV (already provided in repo)  

---