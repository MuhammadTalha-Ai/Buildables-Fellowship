-- Mini Data Warehouse for E-Commerce (PostgreSQL)



-- CLEANUP (drop old tables if re-running script)

DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;


-- DIMENSION TABLES


-- dim_customers: Stores customer data with SCD Type-2 history
CREATE TABLE dim_customers (
    customer_sk      BIGSERIAL PRIMARY KEY,          
    customer_id      VARCHAR(50) NOT NULL,           
    name             VARCHAR(200) NOT NULL,          
    email            VARCHAR(200) NOT NULL,          
    effective_date   DATE NOT NULL,                  
    end_date         DATE,                           
    is_active        CHAR(1) NOT NULL DEFAULT 'Y',   
    -- Constraint: only allow 'Y' or 'N'
    CONSTRAINT chk_is_active CHECK (is_active IN ('Y','N')),
    -- Constraint: end_date must be NULL or after effective_date
    CONSTRAINT scd_date_valid CHECK (end_date IS NULL OR end_date >= effective_date)
);


-- Helpful indexes for fast lookups and versioning
CREATE INDEX idx_dim_customers_bk ON dim_customers (customer_id);
CREATE INDEX idx_dim_customers_active ON dim_customers (customer_id, effective_date, COALESCE(end_date, DATE '9999-12-31'));
CREATE UNIQUE INDEX uq_dim_customers_version ON dim_customers (customer_id, effective_date);

-- dim_products: Stores product details
CREATE TABLE dim_products (
    product_sk   BIGSERIAL PRIMARY KEY,              
    product_id   VARCHAR(50) NOT NULL UNIQUE,        
    name         VARCHAR(200) NOT NULL,              
    category     VARCHAR(100) NOT NULL               
);

-- dim_date: Stores calendar dates for time-based analysis
CREATE TABLE dim_date (
    date_sk     SERIAL PRIMARY KEY,   -- surrogate key
    full_date   DATE NOT NULL UNIQUE, -- actual calendar date
    year        INT NOT NULL,
    month       INT NOT NULL,
    day_of_week INT NOT NULL
);

-- FACT TABLE


-- fact_orders: Stores order transactions (facts)
CREATE TABLE fact_orders (
    order_id       BIGSERIAL PRIMARY KEY,
    order_date_sk  INT NOT NULL,
    customer_sk    INT NOT NULL,
    product_sk     INT NOT NULL,
    quantity       INT NOT NULL,
    price          NUMERIC(10,2) NOT NULL,
    total_amount   NUMERIC(12,2) GENERATED ALWAYS AS (quantity * price) STORED,

    -- Foreign keys
    CONSTRAINT fk_order_date   FOREIGN KEY (order_date_sk) REFERENCES dim_date(date_sk),
    CONSTRAINT fk_customer     FOREIGN KEY (customer_sk)   REFERENCES dim_customers(customer_sk),
    CONSTRAINT fk_product      FOREIGN KEY (product_sk)    REFERENCES dim_products(product_sk)
);

-- Indexes for efficient joins and aggregations
CREATE INDEX idx_fact_orders_date ON fact_orders (order_date_sk);
CREATE INDEX idx_fact_orders_customer ON fact_orders (customer_sk);
CREATE INDEX idx_fact_orders_product ON fact_orders (product_sk);



-- POPULATE DIMENSIONS



-- Insert dates (January to March 2025)
WITH date_series AS (
    SELECT d::date AS full_date
    FROM generate_series(DATE '2025-01-01', DATE '2025-03-31', INTERVAL '1 day') AS s(d)
)
INSERT INTO dim_date (full_date, year, month, day_of_week)
SELECT
    full_date,
    EXTRACT(YEAR FROM full_date)::int AS year,
    EXTRACT(MONTH FROM full_date)::int AS month,
    EXTRACT(ISODOW FROM full_date)::int AS day_of_week
FROM date_series;

-- Insert products

INSERT INTO dim_products (product_id, name, category) VALUES
 ('P-100', 'Aurora Headphones', 'Audio'),
 ('P-200', 'Nimbus Keyboard',  'Accessories'),
 ('P-300', 'Stratus Mouse',    'Accessories'),
 ('P-400', 'Zenith Monitor',   'Displays'),
 ('P-500', 'Pulse Smartwatch', 'Wearables');

-- Insert customers (initial active versions)

INSERT INTO dim_customers (customer_id, name, email, effective_date, end_date, is_active) VALUES
 ('C-001', 'Ayesha Khan',     'ayesha.khan@email.com',  DATE '2025-01-01', NULL, 'Y'),
 ('C-002', 'Bilal Ahmed',     'bilal.ahmed@email.com',  DATE '2025-01-01', NULL, 'Y'),
 ('C-003', 'Fatima Noor',     'fatima.noor@email.com',  DATE '2025-01-01', NULL, 'Y'),
 ('C-004', 'Hamza Ali',       'hamza.ali@email.com',    DATE '2025-01-01', NULL, 'Y'),
 ('C-005', 'Zara Siddiqui',   'zara.siddiqui@email.com',DATE '2025-01-01', NULL, 'Y');


-- Implement SCD Type-2: C-003 changes email on 2025-02-10


-- Step 1: Expire old record
UPDATE dim_customers
   SET end_date = DATE '2025-02-09', is_active = 'N'
 WHERE customer_id = 'C-003' AND is_active = 'Y';

-- Step 2: Insert new record with updated email
INSERT INTO dim_customers (customer_id, name, email, effective_date, end_date, is_active)
SELECT 'C-003', name, 'fatima.noor+new@email.com', DATE '2025-02-10', NULL, 'Y'
FROM dim_customers
WHERE customer_id = 'C-003'
ORDER BY customer_sk DESC
LIMIT 1;


-- POPULATE FACTS (10 sample orders)


-- Order 1: C-001 buys P-100 on 2025-01-05
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT d.date_sk, c.customer_sk, p.product_sk, 1, 199.99
FROM dim_date d
JOIN dim_customers c ON c.customer_id = 'C-001'
JOIN dim_products p ON p.product_id = 'P-100'
WHERE d.full_date = DATE '2025-01-05'
  AND DATE '2025-01-05' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 2: C-002 buys P-300 on 2025-01-08
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-01-08','YYYYMMDD')::int, c.customer_sk, p.product_sk, 2, 79.50
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-300'
WHERE c.customer_id = 'C-002'
  AND DATE '2025-01-08' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 3: C-003 (old version) buys P-400 on 2025-02-01
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-02-01','YYYYMMDD')::int, c.customer_sk, p.product_sk, 1, 329.00
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-400'
WHERE c.customer_id = 'C-003'
  AND DATE '2025-02-01' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 4: C-003 (new version) buys P-500 on 2025-02-11
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-02-11','YYYYMMDD')::int, c.customer_sk, p.product_sk, 1, 249.00
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-500'
WHERE c.customer_id = 'C-003'
  AND DATE '2025-02-11' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 5: C-004 buys P-200 on 2025-02-15
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-02-15','YYYYMMDD')::int, c.customer_sk, p.product_sk, 3, 49.99
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-200'
WHERE c.customer_id = 'C-004'
  AND DATE '2025-02-15' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 6: C-002 buys P-100 on 2025-02-20
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-02-20','YYYYMMDD')::int, c.customer_sk, p.product_sk, 1, 199.99
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-100'
WHERE c.customer_id = 'C-002'
  AND DATE '2025-02-20' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 7: C-001 buys P-400 on 2025-03-01
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-03-01','YYYYMMDD')::int, c.customer_sk, p.product_sk, 2, 329.00
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-400'
WHERE c.customer_id = 'C-001'
  AND DATE '2025-03-01' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 8: C-005 buys P-500 on 2025-03-05
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-03-05','YYYYMMDD')::int, c.customer_sk, p.product_sk, 1, 249.00
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-500'
WHERE c.customer_id = 'C-005'
  AND DATE '2025-03-05' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 9: C-001 buys P-300 on 2025-03-10
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-03-10','YYYYMMDD')::int, c.customer_sk, p.product_sk, 1, 79.50
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-300'
WHERE c.customer_id = 'C-001'
  AND DATE '2025-03-10' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- Order 10: C-005 buys P-200 on 2025-03-22
INSERT INTO fact_orders (order_date_sk, customer_sk, product_sk, quantity, price)
SELECT TO_CHAR(DATE '2025-03-22','YYYYMMDD')::int, c.customer_sk, p.product_sk, 4, 49.99
FROM dim_customers c JOIN dim_products p ON p.product_id = 'P-200'
WHERE c.customer_id = 'C-005'
  AND DATE '2025-03-22' BETWEEN c.effective_date AND COALESCE(c.end_date, DATE '9999-12-31')
LIMIT 1;

-- ANALYTICAL QUERIES

-- 1) Total revenue per product category
SELECT pr.category,
       ROUND(SUM(f.total_amount), 2) AS revenue
FROM fact_orders f
JOIN dim_products pr ON pr.product_sk = f.product_sk
GROUP BY pr.category
ORDER BY revenue DESC;

-- 2) Monthly revenue trend
SELECT d.year,
       d.month,
       ROUND(SUM(f.total_amount), 2) AS revenue
FROM fact_orders f
JOIN dim_date d ON d.date_sk = f.order_date_sk
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 3) Customers with multiple historical records (SCD-2 changes)
SELECT customer_id,
       COUNT(*) AS version_count,
       MIN(effective_date) AS first_effective,
       MAX(COALESCE(end_date, DATE '9999-12-31')) AS last_end_or_active
FROM dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY customer_id;

-- 4) Top 2 customers by spend per month (CTE + RANK)
WITH monthly_spend AS (
    SELECT d.year, d.month, c.customer_id, SUM(f.total_amount) AS total_spend
    FROM fact_orders f
    JOIN dim_date d ON d.date_sk = f.order_date_sk
    JOIN dim_customers c ON c.customer_sk = f.customer_sk
    GROUP BY d.year, d.month, c.customer_id
),
ranked AS (
    SELECT year, month, customer_id, total_spend,
           RANK() OVER (PARTITION BY year, month ORDER BY total_spend DESC) AS rnk
    FROM monthly_spend
)
SELECT year, month, customer_id, ROUND(total_spend, 2) AS total_spend
FROM ranked
WHERE rnk <= 2
ORDER BY year, month, rnk, customer_id;

-- 5) Rank each customer’s orders by date
SELECT c.customer_id,
       d.full_date AS order_date,
       f.order_id,
       ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY d.full_date, f.order_id) AS order_rank
FROM fact_orders f
JOIN dim_customers c ON c.customer_sk = f.customer_sk
JOIN dim_date d ON d.date_sk = f.order_date_sk
ORDER BY c.customer_id, order_rank;