# extract.py
import polars as pl
import os
import logging

logger = logging.getLogger(__name__)

def extract_files(data_dir, file_pattern="*.csv"):
    logger.info("Starting extract_files")
    files = [os.path.join(data_dir, f) for f in os.listdir(data_dir) if f.endswith(".csv")]
    for fp in files:
        logger.info(f"Yielding file: {fp}")
        # Use streaming read to avoid memory blow-up
        yield fp, pl.read_csv(fp, infer_schema_length=1000, low_memory=True, try_parse_dates=False)
    logger.info("Completed extract_files")
