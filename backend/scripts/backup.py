"""Database backup script with rotation."""

import os
import shutil
import sqlite3
from datetime import datetime
from pathlib import Path

BACKUP_DIR = Path("./backups")
DB_PATH = Path("./schedsolicit.db")
MAX_BACKUPS = 5


def backup_database():
    if not DB_PATH.exists():
        print(f"Database file not found at {DB_PATH}")
        return

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    backup_file = BACKUP_DIR / f"schedsolicit_backup_{timestamp}.db"

    print(f"Creating backup: {backup_file} ...")
    # Safe SQLite vacuum into backup
    src_conn = sqlite3.connect(DB_PATH)
    dst_conn = sqlite3.connect(backup_file)
    with dst_conn:
        src_conn.backup(dst_conn)
    dst_conn.close()
    src_conn.close()

    # Verify integrity of backup
    verify_conn = sqlite3.connect(backup_file)
    cursor = verify_conn.cursor()
    cursor.execute("PRAGMA integrity_check;")
    result = cursor.fetchone()
    verify_conn.close()

    if result and result[0] == "ok":
        print(f"Backup verified successfully: {backup_file}")
    else:
        print(f"WARNING: Integrity check failed: {result}")

    # Rotate old backups
    all_backups = sorted(BACKUP_DIR.glob("schedsolicit_backup_*.db"), key=os.path.getmtime)
    if len(all_backups) > MAX_BACKUPS:
        to_delete = all_backups[:-MAX_BACKUPS]
        for f in to_delete:
            f.unlink()
            print(f"Removed older backup: {f}")


if __name__ == "__main__":
    backup_database()
