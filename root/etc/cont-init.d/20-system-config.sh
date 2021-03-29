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
sed -i "s/pm.max_children =.*/pm.max_children = 120/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
sed -i "s/pm.start_servers =.*/pm.start_servers = 12/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
sed -i "s/pm.min_spare_servers =.*/pm.min_spare_servers = 6/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
sed -i "s/pm.max_spare_servers =.*/pm.max_spare_servers = 18/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
cp -r /zoneminder/php-conf/* /etc/php/"${PHP_VERSION}"/fpm/conf.d/
