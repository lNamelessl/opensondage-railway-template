#!/bin/sh
# Framadate on Railway — entrypoint wrapper.
#
# 1. Replicates the upstream image CMD: regenerate the admin .htpasswd from
#    $ADMIN_PASSWORD, envsubst the Apache vhost and app config, fix ownership.
# 2. Starts Apache in the background and waits until it answers on port 80.
# 3. Auto-runs the database schema migration through the admin panel
#    (/admin/migration.php, Apache Basic Auth). The migration is idempotent —
#    it is tracked in the fd_framadate_migration table and safe to re-run on
#    every boot (fresh databases get the full schema bootstrapped).
# 4. Waits on Apache forever (PID 1 behaviour).
set -u

HTPASSWD_PATH="/usr/local/framadate/admin/.htpasswd"

# Railway platform fix: the Metal builder/runtime does not apply image-layer
# whiteouts, so this base image ends up with BOTH mpm_event and mpm_prefork
# enabled and crash-loops with
# "AH00534: apache2: Configuration error: More than one MPM loaded."
# mod_php requires prefork. Deleting files in the container's writable layer
# always works, so force exactly one MPM here at boot instead of build time.
rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf
rm -f /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf
# Make the framadate vhost the only site, so every request on port 80
# (including the Railway healthcheck, which may not send our ServerName)
# is served by the app and not by the Debian 000-default stub.
rm -f /etc/apache2/sites-enabled/000-default.conf

echo "[railway-start] generating admin htpasswd + config from environment"
htpasswd -bc "${HTPASSWD_PATH}" admin "${ADMIN_PASSWORD}"
envsubst < /apache.conf > /etc/apache2/sites-available/framadate.conf
envsubst < /config.php > /usr/local/framadate/app/inc/config.php
chown -R www-data:www-data /usr/local/framadate
chmod 750 -R /usr/local/framadate

echo "[railway-start] starting Apache in background"
apache2-foreground &
APACHE_PID=$!
trap 'kill -TERM "${APACHE_PID}" 2>/dev/null' TERM INT

echo "[railway-start] waiting for Apache to answer on port 80"
tries=0
until curl -fs -o /dev/null "http://127.0.0.1/health.php" 2>/dev/null; do
  tries=$((tries + 1))
  if [ "${tries}" -ge 60 ]; then
    echo "[railway-start] ERROR: Apache did not answer within 60s"
    exit 1
  fi
  sleep 1
done
echo "[railway-start] Apache is up (after ${tries}s)"

echo "[railway-start] running schema migration via /admin/migration.php (idempotent)"
attempt=1
while [ "${attempt}" -le 10 ]; do
  code=$(curl -s -o /tmp/migration.html -w '%{http_code}' \
    -u "admin:${ADMIN_PASSWORD}" \
    "http://127.0.0.1/admin/migration.php" 2>/dev/null || echo 000)
  echo "[railway-start] migration attempt ${attempt}/10: HTTP ${code}"
  if [ "${code}" = "200" ]; then
    echo "[railway-start] schema migration OK"
    break
  fi
  attempt=$((attempt + 1))
  sleep 5
done

if [ "${code}" != "200" ]; then
  echo "[railway-start] WARNING: schema migration did not complete."
  echo "[railway-start] MariaDB may still be initializing; the app stays up."
  echo "[railway-start] Re-run it manually: open /admin/migration.php in a browser"
  echo "[railway-start] (user 'admin', password = ADMIN_PASSWORD variable)."
fi

echo "[railway-start] handing over to Apache (pid ${APACHE_PID})"
wait "${APACHE_PID}"
