#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="zm-config"

## Link ZoneMinder config and data folders

if [ ! -f "/config/zm.conf" ]; then
  init "${program_name}" "Configuring ZoneMinder Configuration folder"
  s6-setuidgid www-data \
    cp -r /zoneminder/defaultconfig/* /config
fi

if [ ! -d "/data/events" ]; then
  init "${program_name}" "Configuring ZoneMinder Data folder"
  s6-setuidgid www-data \
    mkdir -p \
      /data/events \
      /data/images
fi

## Configure ZoneMinder DB
info "${program_name}" "Configuring ZoneMinder db Settings"
sed -i "s/ZM_DB_USER=.*$/ZM_DB_USER=${MYSQL_USER}/g" /config/zm.conf
sed -i "s/ZM_DB_PASS=.*$/ZM_DB_PASS=${MYSQL_PASSWORD}/g" /config/zm.conf
# These cannot be changed
sed -i "s/ZM_DB_NAME=.*$/ZM_DB_NAME=zm/g" /config/zm.conf
sed -i "s/ZM_DB_HOST=.*$/ZM_DB_HOST=db/g" /config/zm.conf

if [[ ! -z ${ZM_SERVER_HOST} ]]; then
  info "${program_name}" "Configuring ZoneMinder ZM_SERVER_HOST for Multi-Server Support"
  sed -i "s/ZM_SERVER_HOST=.*$/ZM_SERVER_HOST=${ZM_SERVER_HOST}/g" /config/zm.conf
fi
