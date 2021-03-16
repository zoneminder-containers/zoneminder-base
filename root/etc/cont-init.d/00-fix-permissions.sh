#!/usr/bin/with-contenv bash

PUID=${PUID:-911}
PGID=${PGID:-911}

echo "[fix-permissions] Reconfiguring GID and UID"
groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" www-data

echo "[fix-permissions] User uid:    $(id -u www-data)"
echo "[fix-permissions] User gid:    $(id -g www-data)"

echo "[fix-permissions] Setting permissions for /config"
chown -R www-data:www-data /config

echo "[fix-permissions] Setting permissions for /data"
chown -R www-data:www-data /data

echo "[fix-permissions] Setting permissions for /log"
chown -R www-data:www-data /log
