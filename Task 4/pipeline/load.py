# load.py
import logging
from sqlalchemy import create_engine
import pandas as pd

logger = logging.getLogger(__name__)

def get_engine(db_conf):
    uri = f"postgresql+psycopg2://{db_conf['user']}:{db_conf['password']}@{db_conf['host']}:{db_conf['port']}/{db_conf['database']}"
    return create_engine(uri)

def load_clean_events(df, engine):
    logger.info("Starting load_clean_events")
    # convert polars to pandas for to_sql or use COPY approach for speed
    df_pd = df.to_pandas()
    df_pd.to_sql("events_clean", engine, if_exists="append", index=False, method="multi", chunksize=5000)
    logger.info("Completed load_clean_events")

def load_hourly_metrics(agg_df, engine):
    logger.info("Starting load_hourly_metrics")
    df_pd = agg_df.to_pandas()
    df_pd.to_sql("hourly_metrics", engine, if_exists="append", index=False, method="multi", chunksize=2000)
    logger.info("Completed load_hourly_metrics")

def store_malformed(malformed_list, engine, source_file):
    if not malformed_list:
        return
    logger.info("Starting store_malformed")
    import pandas as pd
    df = pd.DataFrame([{
        "source_file": source_file,
        "line_number": i+1,
        "raw_line": str(row),
        "error_reason": "missing_event_id_or_time"
    } for i, row in enumerate(malformed_list)])
    df.to_sql("malformed_events", engine, if_exists="append", index=False)
    logger.info("Completed store_malformed")
