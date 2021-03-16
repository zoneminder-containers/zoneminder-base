#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="fix-permissions"

PUID=${PUID:-911}
PGID=${PGID:-911}

info "${program_name}" "Reconfiguring GID and UID"
groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" www-data

info "${program_name}" "User uid:    $(id -u www-data)"
info "${program_name}" "User gid:    $(id -g www-data)"

info "${program_name}" "Setting permissions for /config"
chown -R www-data:www-data /config

info "${program_name}" "Setting permissions for /data"
chown -R www-data:www-data /data

info "${program_name}" "Setting permissions for /log"
chown -R www-data:www-data /log
