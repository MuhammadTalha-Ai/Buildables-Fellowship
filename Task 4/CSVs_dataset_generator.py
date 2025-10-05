import csv
import os
import random
import string
from datetime import datetime, timedelta
from pathlib import Path

# -------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------
OUTPUT_DIR = Path("raw_events")       # Folder to store CSVs
NUM_FILES = 5                         # How many CSV files to create
ROWS_PER_FILE = 2_000_000             # Rows per CSV (~250–300 MB each)
START_DATE = datetime(2025, 1, 1)     # Start of event timeline
DAYS_SPAN = 90                        # Days of data

# Sample games and modes
GAMES = [
    "Spider-Man 2", "Demon's Souls", "God of War Ragnarok",
    "Horizon Forbidden West", "Gran Turismo 7",
    "Returnal", "Ratchet & Clank: Rift Apart"
]
MODES = ["single_player", "co_op", "multiplayer"]

# -------------------------------------------------------
# HELPER FUNCTIONS
# -------------------------------------------------------
def random_username():
    return ''.join(random.choices(string.ascii_lowercase, k=8))

def random_timestamp():
    # Random timestamp within the configured window
    delta = timedelta(days=random.randint(0, DAYS_SPAN),
                      seconds=random.randint(0, 24*3600))
    return (START_DATE + delta).strftime("%Y-%m-%d %H:%M:%S")

def random_session_minutes():
    return random.randint(1, 180)  # 1 to 3 hours

# -------------------------------------------------------
# DATA GENERATOR
# -------------------------------------------------------
def generate_csv_files():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for fnum in range(1, NUM_FILES + 1):
        filename = OUTPUT_DIR / f"ps5_events_part_{fnum}.csv"
        with open(filename, mode="w", newline="", encoding="utf-8") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow([
                "event_id", "username", "game_title",
                "mode", "session_minutes", "event_time"
            ])

            for i in range(ROWS_PER_FILE):
                event_id = f"EVT-{fnum}-{i}"
                row = [
                    event_id,
                    random_username(),
                    random.choice(GAMES),
                    random.choice(MODES),
                    random_session_minutes(),
                    random_timestamp()
                ]
                writer.writerow(row)

        print(f"✅ Created {filename} with {ROWS_PER_FILE:,} rows.")

if __name__ == "__main__":
    generate_csv_files()
    print(f"🎮 Finished generating {NUM_FILES} files in '{OUTPUT_DIR}'")
