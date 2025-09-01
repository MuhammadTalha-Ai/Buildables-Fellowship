 
# Mini DW: OLTP vs OLAP, Surrogate Keys, and SCD-2 — Short Write-Up

**OLTP vs OLAP modeling.**  
OLTP systems are built for transaction processing: highly normalized schemas (3NF), many small reads/writes, strict integrity, and low-latency updates (e.g., `orders`, `payments`). OLAP systems are built for analytics: denormalized star/snowflake schemas, large scans, and aggregations across historical data (e.g., `fact_orders` with dimensional lookups). In OLAP, we optimize for query speed and simplicity (surrogate keys, precomputed grain, conformed dimensions) rather than minimizing redundancy.

**Why surrogate keys matter in dimensions.**  
Surrogate keys are stable, single-column identifiers independent of business keys. They (1) prevent natural-key churn from breaking joins, (2) enable SCD versioning because each historical row gets a new surrogate, (3) keep fact tables narrow and performant, and (4) let you safely integrate multiple source systems with conflicting natural keys. Business keys still exist to preserve identity, but facts always join via surrogate keys.

**What I learned about SCD Type-2.**  
SCD-2 preserves full history by closing old versions (setting `end_date` and `is_active='N'`) and inserting a new row with the same business key and a fresh surrogate. Facts reference the version that was effective at the order date (using `effective_date <= order_date < end_date_or_infinity`). This keeps historical reports accurate even if customer attributes (like email) change later. The schema and inserts demonstrate this pattern, and the queries show how the history supports category revenue, monthly trends, change detection, and per-month customer rankings.
