# runner.py
import logging
from config import DATA_DIR, ARCHIVE_DIR, DB
from pipeline.extract import extract_files
from pipeline.transform import clean_transform, aggregate_hourly
from pipeline.validate import validate_data
from pipeline.load import get_engine, load_clean_events, load_hourly_metrics, store_malformed
from pipeline.archive import archive_raw
from datetime import datetime
from pipeline.utils import setup_logging

def run_pipeline():
    setup_logging()
    logger = logging.getLogger(__name__)
    engine = get_engine(DB)
    start_time = datetime.utcnow()
    logger.info(f"Pipeline run started: {start_time.isoformat()}")

    steps_status = {}

    try:
        for fp, df in extract_files(DATA_DIR):
            step_name = f"process_{fp}"
            try:
                logger.info(f"Processing file {fp}")
                cleaned = clean_transform(df)
                malformed = validate_data(cleaned, fp)
                if malformed:
                    store_malformed(malformed, engine, fp)
                agg = aggregate_hourly(cleaned)
                # Load cleaned rows and aggregates
                load_clean_events(cleaned, engine)
                load_hourly_metrics(agg, engine)
                archive_raw(fp, ARCHIVE_DIR)
                steps_status[step_name] = "SUCCESS"
            except Exception as e:
                logger.exception(f"FAILED step {step_name}: {e}")
                steps_status[step_name] = f"FAILED: {e}"
                raise  # stop whole pipeline
    except Exception as e:
        logger.exception(f"Pipeline aborted due to failure: {e}")

    finally:
        end_time = datetime.utcnow()
        logger.info(f"Pipeline run ended: {end_time.isoformat()}")
        # Summary
        logger.info("Run Summary:")
        for name, status in steps_status.items():
            logger.info(f"{name} : {status}")

if __name__ == "__main__":
    run_pipeline()
