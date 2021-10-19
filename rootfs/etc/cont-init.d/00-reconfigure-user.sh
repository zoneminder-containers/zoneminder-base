#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="reconfigure-user"

PUID=${PUID:-911}
PGID=${PGID:-911}

if [ "${PUID}" -ne 911 ] || [ "${PGID}" -ne 911 ]; then
  echo "Reconfiguring GID and UID" | info "[${program_name}] "
  groupmod -o -g "$PGID" www-data
  usermod -o -u "$PUID" www-data

  echo "User uid:    $(id -u www-data)" | info "[${program_name}] "
  echo "User gid:    $(id -g www-data)" | info "[${program_name}] "

  echo "Setting permissions for user www-data" | info "[${program_name}] "
  chown -R www-data:www-data \
    /config \
    /zoneminder
  chmod -R 755 \
    /config \
    /zoneminder
else
  echo "Setting permissions for user www-data" | info "[${program_name}] "
  chown -R www-data:www-data \
    /config
  chmod -R 755 \
    /config
fi

echo "Setting permissions for user nobody at /log" | info "[${program_name}] "
chown -R nobody:nogroup \
  /log
chmod -R 755 \
  /log
