from config import DB
from pipeline.load import get_engine
from sqlalchemy import text

engine = get_engine(DB)

try:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT version();"))
        print("✅ Connection inside pipeline works!", result.fetchone())
except Exception as e:
    print("❌ Error connecting:", e)
