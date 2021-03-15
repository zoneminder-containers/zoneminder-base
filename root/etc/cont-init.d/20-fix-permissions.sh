#!/usr/bin/with-contenv bash

PUID=${PUID:-911}
PGID=${PGID:-911}

groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" www-data

echo "User uid:    $(id -u www-data)
User gid:    $(id -g www-data)"

chown -R www-data:www-data /config
chown -R www-data:www-data /data
chown -R www-data:www-data /log
