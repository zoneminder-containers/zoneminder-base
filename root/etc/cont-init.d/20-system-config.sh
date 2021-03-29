#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="system-config"

## Configure Timezone
echo "Setting system timezone to ${TZ}" | info "${program_name}"
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime

## Set PHP Time

echo "Configuring PHP Time" | info "${program_name}"
# PHP_INSTALL=`php -r "echo php_ini_loaded_file().PHP_EOL;"`
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION;" && echo -n "." && php -r "echo PHP_MINOR_VERSION;")
echo -n "${PHP_VERSION}" > /var/run/s6/container_environment/PHP_VERSION

echo "date.timezone = ${TZ}" >> /etc/php/"${PHP_VERSION}"/fpm/conf.d/30-zoneminder-time.ini

echo "Applying PHP Optimizations" | info "${program_name}"

cp -r /zoneminder/php-conf/* /etc/php/"${PHP_VERSION}"/fpm/conf.d/
