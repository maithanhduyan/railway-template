#!/bin/sh
set -e

# ── Set defaults for env vars (used by envsubst in odoo.conf) ──
export ADDONS_PATH="${ADDONS_PATH:-/mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons}"
export DATA_DIR="${DATA_DIR:-/var/lib/odoo}"
export ADMIN_PASSWD="${ADMIN_PASSWD:-admin}"

export DB_HOST="${DB_HOST:-postgres}"
export DB_PORT="${DB_PORT:-5432}"
export DB_USER="${DB_USER:-odoo}"
export DB_PASSWORD="${DB_PASSWORD:-odoo}"
export DB_NAME="${DB_NAME:-odoo}"
export DB_MAXCONN="${DB_MAXCONN:-64}"
export DB_SSLMODE="${DB_SSLMODE:-prefer}"
export DB_TEMPLATE="${DB_TEMPLATE:-template0}"
export DBFILTER="${DBFILTER:-}"
export LIST_DB="${LIST_DB:-True}"
export UNACCENT="${UNACCENT:-False}"

export PORT="${PORT:-8069}"
export WS_PORT="${WS_PORT:-8072}"
export PROXY_MODE="${PROXY_MODE:-True}"

export WORKERS="${WORKERS:-0}"
export MAX_CRON_THREADS="${MAX_CRON_THREADS:-2}"
export LIMIT_MEMORY_HARD="${LIMIT_MEMORY_HARD:-2684354560}"
export LIMIT_MEMORY_SOFT="${LIMIT_MEMORY_SOFT:-2147483648}"
export LIMIT_TIME_CPU="${LIMIT_TIME_CPU:-600}"
export LIMIT_TIME_REAL="${LIMIT_TIME_REAL:-1200}"
export LIMIT_REQUEST="${LIMIT_REQUEST:-8192}"

export LOG_LEVEL="${LOG_LEVEL:-info}"
export LOG_FILE="${LOG_FILE:-}"
export LOG_HANDLER="${LOG_HANDLER:-:INFO}"
export LOG_ROTATE="${LOG_ROTATE:-True}"

export SMTP_HOST="${SMTP_HOST:-localhost}"
export SMTP_PORT="${SMTP_PORT:-25}"
export SMTP_USER="${SMTP_USER:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"
export SMTP_SSL="${SMTP_SSL:-False}"
export EMAIL_FROM="${EMAIL_FROM:-}"

# with_demo is the inverse of WITHOUT_DEMO
case "${WITHOUT_DEMO:-True}" in
  [Ff]alse|0|no) export WITHOUT_DEMO="True" ;;
  *)             export WITHOUT_DEMO="False" ;;
esac

# ── Render config template ──
envsubst < /etc/odoo/odoo.conf.template > /etc/odoo/odoo.conf

# ── Fix ownership for mounted volumes (only if needed) ──
find /var/lib/odoo /var/log/odoo -not -user odoo -exec chown odoo:odoo {} + 2>/dev/null || true
chown odoo:odoo /etc/odoo/odoo.conf

# ── S3 bucket init (wait for MinIO, run as odoo) ──
if [ -n "$S3_ENDPOINT" ]; then
  case "$S3_ENDPOINT" in
    http://*|https://*) ;;
    *.railway.internal*) S3_ENDPOINT="http://${S3_ENDPOINT}"; export S3_ENDPOINT ;;
    *) S3_ENDPOINT="https://${S3_ENDPOINT}"; export S3_ENDPOINT ;;
  esac
  echo "Waiting for S3/MinIO (${S3_ENDPOINT})..."
  for i in $(seq 1 30); do
    gosu odoo python3 << 'PYEOF' && break || sleep 2
import os, boto3
from botocore.exceptions import ClientError
client = boto3.client('s3',
    endpoint_url=os.environ['S3_ENDPOINT'],
    aws_access_key_id=os.environ['S3_ACCESS_KEY'],
    aws_secret_access_key=os.environ['S3_SECRET_KEY'],
    region_name=os.environ.get('S3_REGION', 'us-east-1'))
bucket = os.environ.get('S3_BUCKET', 'odoo')
try:
    client.head_bucket(Bucket=bucket)
    print(f'S3 bucket "{bucket}" is ready')
except ClientError as e:
    if e.response['Error']['Code'] in ('404', 'NoSuchBucket'):
        client.create_bucket(Bucket=bucket)
        print(f'Created S3 bucket: {bucket}')
    else:
        raise
PYEOF
  done
fi

# ── Build extra CLI args (runtime-only flags) ──
set -- odoo --config=/etc/odoo/odoo.conf

[ -n "$ODOO_INIT" ]   && set -- "$@" "--init=${ODOO_INIT}"
[ -n "$ODOO_UPDATE" ] && set -- "$@" "--update=${ODOO_UPDATE}"
[ -n "$ODOO_DEV" ]    && set -- "$@" "--dev=${ODOO_DEV}"

exec gosu odoo "$@" 2>&1
