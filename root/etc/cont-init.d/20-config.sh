#!/usr/bin/with-contenv bash

## Link ZoneMinder config and data folders

if [ ! -f "/zoneminder/config/zm.conf" ]; then
  echo "Configuring ZoneMinder Configuration for First Run"
  cp -r /zoneminder/config /config
fi

ln -sf /config /zoneminder/config

if [ ! -d "/data" ]; then
  echo "Configuring ZoneMinder Data folder for First Run"
  mkdir -p \
    /data/events \
    /data/images
fi

ln -sf /data /zoneminder/content

## Configure ZoneMinder DB
sed -i "s/ZM_DB_NAME=.*$/ZM_DB_NAME=$MYSQL_DATABASE/g" /zoneminder/config/zm.conf
sed -i "s/ZM_DB_USER=.*$/ZM_DB_USER=$MYSQL_USER/g" /zoneminder/config/zm.conf
sed -i "s/ZM_DB_PASS=.*$/ZM_DB_PASS=$MYSQL_PASSWORD/g" /zoneminder/config/zm.conf
sed -i "s/ZM_DB_HOST=.*$/ZM_DB_HOST=db/g" /zoneminder/config/zm.conf

## Configure Timezone
echo "Setting timezone to ${TZ}"
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime

## Set PHP Time

# PHP_INSTALL=`php -r "echo php_ini_loaded_file().PHP_EOL;"`
PHP_VERSION=`php -r "echo PHP_MAJOR_VERSION;" && echo -n "." && php -r "echo PHP_MINOR_VERSION;"`
# Uncomment date.timezone
sed -i "s/;date.timezone/date.timezone/" /etc/php/${PHP_VERSION}/apache2/php.ini
# Configure Time
sed -i "s:date.timezone =.*$:date.timezone = ${TZ}:" /etc/php/${PHP_VERSION}/apache2/php.ini
