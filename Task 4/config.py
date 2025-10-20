# config.py
import os

DATA_DIR = os.path.join(os.getcwd(), "data")
ARCHIVE_DIR = os.path.join(os.getcwd(), "archive")
LOG_FILE = os.path.join(os.getcwd(), "pipeline_run.log")

DB = {
    "user": "postgres",
    "password": "talha611",
    "host": "localhost",
    "port": 5432,
    "database": "gameanalytics"
}
