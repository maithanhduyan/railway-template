#!/bin/bash

# Odoo Backup Cron Job Script
# Backup database bằng pg_dump + filestore
# Chạy hàng ngày và giữ lại 10 file mới nhất

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/odoobackup"
DB_NAME="taya_db"
DB_USER="odoo"
PG_CONTAINER="postgresql"
ODOO_CONTAINER="odoo-15"
DATE_TIME=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE_TIME}.sql"
KEEP_BACKUPS=1

mkdir -p "$BACKUP_DIR"

echo "$(date): Starting Odoo backup (pg_dump + filestore)..."

# 1. Database backup via pg_dump (plain SQL, compatible with any PG version)
echo "$(date): Dumping database $DB_NAME..."
if docker exec "$PG_CONTAINER" pg_dump -U "$DB_USER" -Fp "$DB_NAME" > "$BACKUP_FILE"; then
    # Verify it's a real SQL dump
    if head -5 "$BACKUP_FILE" | grep -q "PostgreSQL database dump"; then
        FILE_SIZE=$(stat -c%s "$BACKUP_FILE")
        echo "$(date): Database dump OK - $(basename "$BACKUP_FILE") ($(numfmt --to=iec $FILE_SIZE))"
    else
        echo "$(date): ERROR - pg_dump output is not a valid SQL dump"
        rm -f "$BACKUP_FILE"
        exit 1
    fi
else
    echo "$(date): ERROR - pg_dump failed"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# 2. Filestore backup (tar.gz)
FILESTORE_FILE="$BACKUP_DIR/${DB_NAME}_filestore_${DATE_TIME}.tar.gz"
echo "$(date): Backing up filestore..."
if docker exec "$ODOO_CONTAINER" tar czf - -C /var/lib/odoo/filestore "$DB_NAME" > "$FILESTORE_FILE" 2>/dev/null; then
    FSTORE_SIZE=$(stat -c%s "$FILESTORE_FILE")
    echo "$(date): Filestore OK - $(basename "$FILESTORE_FILE") ($(numfmt --to=iec $FSTORE_SIZE))"
else
    echo "$(date): WARNING - Filestore backup failed (database backup still saved)"
fi

# 3. Cleanup old backups (giữ lại $KEEP_BACKUPS file mới nhất mỗi loại)
cd "$BACKUP_DIR"
ls -t ${DB_NAME}_*.sql 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm
ls -t ${DB_NAME}_filestore_*.tar.gz 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r rm
echo "$(date): Old backups cleaned up (keeping $KEEP_BACKUPS most recent)"

echo "$(date): Backup completed successfully"