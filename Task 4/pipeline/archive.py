# archive.py
import os
import shutil
import logging

logger = logging.getLogger(__name__)

def archive_raw(file_path, archive_dir):
    """Move a processed file into the archive folder."""
    os.makedirs(archive_dir, exist_ok=True)
    dest = os.path.join(archive_dir, os.path.basename(file_path))
    shutil.move(file_path, dest)
    logger.info(f"Archived {file_path} -> {dest}")
