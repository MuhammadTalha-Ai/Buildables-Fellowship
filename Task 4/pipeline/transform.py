# transform.py
import polars as pl
import logging
from dateutil import parser as dtparser

logger = logging.getLogger(__name__)

def clean_transform(df: pl.DataFrame):
    logger.info("Starting clean_transform")
    # ensure platform column exists; filter for PS5 (case-insensitive)
    # Normalize and filter for PS5 games only if 'platform' column exists
    if "platform" in df.columns:
        df = df.with_columns([
            pl.col("platform").fill_null("").str.to_lowercase().alias("platform")
        ])
        df = df.filter(pl.col("platform").str.contains("ps5"))
    else:
        print("⚠️ 'platform' column not found — skipping PS5 filter.")

    # parse timestamp (assume original timestamp column name 'timestamp')
    # Convert to UTC-aware datetime if timezone missing: best-effort parse
    # Handle timestamps safely
    if "timestamp" in df.columns:
        df = df.with_columns([
            pl.col("timestamp").str.strptime(pl.Datetime, strict=False).alias("event_time")
        ])
    elif "event_time" in df.columns:
        df = df.with_columns([
            pl.col("event_time").str.strptime(pl.Datetime, strict=False).alias("event_time")
        ])
    else:
        print("⚠️ No timestamp or event_time column found — skipping datetime parsing.")

    # compute hour start for aggregation
    df = df.with_columns([
        pl.col("event_time").dt.truncate("1h").alias("hour_start")
    ])
    # For play_time_seconds ensure numeric
    df = df.with_columns([
    (pl.col("session_minutes") * 60).cast(pl.Float64).fill_null(0.0).alias("play_time_seconds")
    ])

    logger.info("Completed clean_transform")
    return df

def aggregate_hourly(df: pl.DataFrame):
    logger.info("Starting aggregate_hourly")
    agg = df.group_by(["game_title", "hour_start"]).agg([
    pl.count().alias("event_count"),
    pl.col("play_time_seconds").sum().alias("total_play_time_seconds"),
    ])

    logger.info("Completed aggregate_hourly")
    return agg
