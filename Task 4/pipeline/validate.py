# validate.py
import logging
import polars as pl

logger = logging.getLogger(__name__)

def validate_data(df: pl.DataFrame, source_file: str):
    logger.info("Starting validate_data")
    malformed = []
    # Example checks: missing event_id or event_time null
    bad = df.filter(pl.col("event_id").is_null() | pl.col("event_time").is_null())
    if bad.height > 0:
        logger.warning(f"Found {bad.height} malformed rows in {source_file}")
        # Convert bad rows to list of dicts (or save CSV/JSON)
        malformed = bad.to_dicts()
    logger.info("Completed validate_data")
    return malformed
