# 🎮 Game Dynasty – Data Warehouse (SCD-2 Implementation)

This project demonstrates a **production-level Slowly Changing Dimension Type 2 (SCD-2)** implementation using SQL.  
The example tracks changes in **PS5 Games attributes** such as price, genre, developer, and PS Plus subscription status.  

---

## 🚀 Scenario
We maintain a **dimension table** of PS5 games.  
When attributes change, instead of overwriting the row, we:
- Mark the old record as **inactive** (`end_date`, `is_active = FALSE`)  
- Insert a **new version** with updated values and a new surrogate key  

Changes are detected using a **row-level hash (MD5)** across attributes.

---

## 📊 Schema Design

**Dimension Table (dim_ps5_games):**
- `game_sk` (Surrogate Key, PK)  
- `game_id` (Business Key)  
- Attributes: `title`, `genre`, `developer`, `price`, `ps_plus_included`  
- `row_hash` → MD5 hash of attribute values  
- SCD columns: `start_date`, `end_date`, `is_active`  

**Staging Table (stg_ps5_games):**
- Latest snapshot of incoming data  
- Same attributes as dimension table (without SCD columns)  

---

## 🔄 Flow Diagram (SCD-2 Logic)

```mermaid
flowchart LR
    A[Staging Table<br>stg_ps5_games<br>New Snapshot Data] --> C[Compare on<br>game_id & row_hash]
    B[Dimension Table<br>dim_ps5_games<br>History of Games] --> C[Compare on<br>game_id & row_hash]

    C --> D[Unchanged → Do Nothing]
    C --> E[Changed → Expire Old Row<br>+ Insert New Row]
    C --> F[New Game → Insert New Row]
