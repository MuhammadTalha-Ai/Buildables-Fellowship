# 📊 E-Commerce Database Analytics Project

This project demonstrates how to design, populate, and analyze a simple **E-commerce database** using **PostgreSQL**.  
It includes schema creation, sample data insertion, and a collection of analytical queries to extract insights.

---

## 🚀 Project Steps

### Step 1: Database Schema
- **Customers**: Stores customer details.  
- **Products**: Stores product catalog.  
- **Orders**: Stores purchase information with foreign keys to `customers` and `products`.  

### Step 2: Sample Data
- 10 Customers  
- 5 Products  
- 20 Orders  

The dataset ensures:
- Some customers have multiple orders.  
- Some products are ordered multiple times.  

### Step 3: Analytics Queries
The SQL file includes queries for:
- Customers ordering more than 2 different products.  
- Top 3 most ordered products by quantity.  
- Total spending per customer.  
- Customers with no orders.  
- Products never ordered.  
- Latest order date per customer.  
- A view `customer_spend_summary` for aggregated spending.  
- Index on `orders.customer_id` to optimize queries.  
- Top 2 customers per category by spend (CTE + `ROW_NUMBER()`).  
- Monthly sales trend (CTE).  
- Ranking orders by date per customer.  
- Cumulative spending over time per customer.  
- Highest revenue product in each category (using `RANK()`).  

---

## 🛠️ How to Use
1. Clone this repository:
   ```bash
   git clone git clone https://github.com/MuhammadTalha-Ai/Buildables-Fellowship
   cd Task 1
