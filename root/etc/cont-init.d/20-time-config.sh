#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="time-config"

## Configure Timezone
echo "Setting system timezone to ${TZ}" | info "${program_name}"
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime

## Set PHP Time

echo "Configuring PHP Time" | info "${program_name}"
# PHP_INSTALL=`php -r "echo php_ini_loaded_file().PHP_EOL;"`
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION;" && echo -n "." && php -r "echo PHP_MINOR_VERSION;")
echo -n ${PHP_VERSION} > /var/run/s6/container_environment/PHP_VERSION
# Uncomment date.timezone
sed -i "s/;date.timezone/date.timezone/" /etc/php/"${PHP_VERSION}"/fpm/php.ini
# Configure Time
sed -i "s:date.timezone =.*$:date.timezone = ${TZ}:" /etc/php/"${PHP_VERSION}"/fpm/php.ini
