import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="gameanalytics",   # 👈 replace with your DB name
        user="postgres",
        password="talha611",        # 👈 replace with your password
        port=5432
    )
    print("✅ Connection successful!")
    conn.close()
except Exception as e:
    print("❌ Connection failed:", e)
