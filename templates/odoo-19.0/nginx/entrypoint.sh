#!/bin/sh
set -e

# Toggle database manager access
if [ "${ENABLE_DB_MANAGER}" = "true" ]; then
    export DB_MANAGER_RULE='proxy_pass $odoo_http; proxy_redirect off;'
else
    export DB_MANAGER_RULE="return 403;"
fi

# Websocket proxy: workers=0 → HTTP port, workers>0 → gevent port
if [ "${ODOO_WORKERS:-0}" = "0" ]; then
    export WEBSOCKET_PROXY_RULE='$odoo_http'
else
    export WEBSOCKET_PROXY_RULE='$odoo_ws'
fi

# Extract DNS resolver from /etc/resolv.conf for dynamic upstream resolution
# This prevents nginx from caching stale IPs when upstream services redeploy
NGINX_RESOLVER=$(grep -m1 '^nameserver' /etc/resolv.conf | awk '{print $2}')
NGINX_RESOLVER="${NGINX_RESOLVER:-127.0.0.11}"
# Wrap IPv6 addresses in brackets for nginx resolver directive
case "$NGINX_RESOLVER" in
    *:*) NGINX_RESOLVER="[${NGINX_RESOLVER}]" ;;
esac
export NGINX_RESOLVER

# Substitute environment variables into nginx config template
envsubst '${ODOO_HOST} ${ODOO_PORT} ${ODOO_WS_PORT} ${MINIO_HOST} ${MINIO_PORT} ${DB_MANAGER_RULE} ${WEBSOCKET_PROXY_RULE} ${NGINX_RESOLVER}' \
    < /etc/nginx/odoo.conf.template \
    > /etc/nginx/conf.d/default.conf
