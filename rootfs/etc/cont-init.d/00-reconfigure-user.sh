#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="reconfigure-user"

PUID=${PUID:-911}
PGID=${PGID:-911}

echo "Reconfiguring GID and UID" | info "[${program_name}] "
groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" www-data

echo "User uid:    $(id -u www-data)" | info "[${program_name}] "
echo "User gid:    $(id -g www-data)" | info "[${program_name}] "
