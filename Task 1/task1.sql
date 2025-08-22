-- Step 1: Schema Definition

-- Customers Table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products Table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price NUMERIC(10,2) CHECK (price > 0)
);

-- Orders Table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    quantity INT CHECK (quantity > 0),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 2: Insert Sample Data

-- Insert Customers
INSERT INTO customers (name, email) VALUES
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com'),
('Diana Prince', 'diana@example.com'),
('Ethan Hunt', 'ethan@example.com'),
('Fiona Gallagher', 'fiona@example.com'),
('George Martin', 'george@example.com'),
('Hannah Lee', 'hannah@example.com'),
('Ian Wright', 'ian@example.com'),
('Julia Roberts', 'julia@example.com');

-- Insert Products
INSERT INTO products (name, category, price) VALUES
('Laptop', 'Electronics', 1200.00),
('Smartphone', 'Electronics', 800.00),
('Headphones', 'Accessories', 150.00),
('Desk Chair', 'Furniture', 250.00),
('Coffee Maker', 'Appliances', 100.00);

-- Insert Orders
INSERT INTO orders (customer_id, product_id, quantity) VALUES
(1, 1, 1),
(1, 3, 2),
(2, 2, 1),
(2, 4, 1),
(3, 5, 1),
(3, 1, 1),
(4, 2, 2),
(5, 3, 1),
(5, 5, 1),
(6, 4, 1),
(6, 1, 1),
(7, 2, 1),
(7, 3, 2),
(8, 5, 1),
(8, 4, 1),
(9, 1, 1),
(9, 2, 1),
(10, 3, 1),
(10, 5, 1),
(10, 2, 1);

-- Step 3: Analytics Queries

-- 1. Customers who ordered more than 2 different products
SELECT c.customer_id, c.name, COUNT(DISTINCT o.product_id) AS product_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.product_id) > 2;

-- 2. Top 3 most ordered products by quantity
SELECT p.product_id, p.name, SUM(o.quantity) AS total_quantity
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.name
ORDER BY total_quantity DESC
LIMIT 3;

-- 3. Each customer’s total spending
SELECT c.customer_id, c.name, SUM(p.price * o.quantity) AS total_spending
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.name
ORDER BY total_spending DESC;

-- 4. Customers who never placed an order
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 5. Products never ordered
SELECT p.product_id, p.name
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
WHERE o.order_id IS NULL;

-- 6. Latest order date per customer
SELECT c.customer_id, c.name, MAX(o.order_date) AS latest_order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

-- 7. Customer spend summary view
CREATE VIEW customer_spend_summary AS
SELECT c.customer_id, c.name, SUM(p.price * o.quantity) AS total_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.name;

-- 8. Index on orders.customer_id
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- 9. Top 2 customers by spending per category (CTE + ROW_NUMBER)
WITH customer_category_spend AS (
    SELECT c.customer_id, c.name, p.category,
           SUM(p.price * o.quantity) AS spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN products p ON o.product_id = p.product_id
    GROUP BY c.customer_id, c.name, p.category
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY spend DESC) AS rn
    FROM customer_category_spend
)
SELECT customer_id, name, category, spend
FROM ranked
WHERE rn <= 2;

-- 10. Monthly sales trend (CTE)
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', o.order_date) AS month,
           SUM(p.price * o.quantity) AS total_revenue
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT * FROM monthly_sales ORDER BY month;

-- 11. Rank each customer’s orders by order_date
SELECT o.order_id, o.customer_id, o.order_date,
       RANK() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS order_rank
FROM orders o;

-- 12. Cumulative spending over time
SELECT c.customer_id, c.name, o.order_date,
       SUM(p.price * o.quantity) OVER (
           PARTITION BY c.customer_id
           ORDER BY o.order_date
       ) AS cumulative_spending
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
ORDER BY c.customer_id, o.order_date;

-- 13. Highest revenue product per category
WITH product_revenue AS (
    SELECT p.product_id, p.name, p.category,
           SUM(p.price * o.quantity) AS revenue
    FROM products p
    JOIN orders o ON p.product_id = o.product_id
    GROUP BY p.product_id, p.name, p.category
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM product_revenue
)
SELECT product_id, name, category, revenue
FROM ranked
WHERE rn = 1;
