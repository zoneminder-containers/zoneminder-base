#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="system-config"

## Configure Timezone
echo "Setting system timezone to ${TZ}" | info "[${program_name}] "
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime

## Set PHP Time

echo "Configuring PHP Time" | info "[${program_name}] "
# PHP_INSTALL=`php -r "echo php_ini_loaded_file().PHP_EOL;"`
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION;" && echo -n "." && php -r "echo PHP_MINOR_VERSION;")
echo -n "${PHP_VERSION}" > /var/run/s6/container_environment/PHP_VERSION

echo "date.timezone = ${TZ}" >> /etc/php/"${PHP_VERSION}"/fpm/conf.d/30-zoneminder-time.ini

echo "Applying PHP Optimizations" | info "[${program_name}] "
sed -i "s/pm.max_children =.*/pm.max_children = ${PHP_MAX_CHILDREN}/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
sed -i "s/pm.start_servers =.*/pm.start_servers = ${PHP_START_SERVERS}/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
sed -i "s/pm.min_spare_servers =.*/pm.min_spare_servers = ${PHP_MIN_SPARE_SERVERS}/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf
sed -i "s/pm.max_spare_servers =.*/pm.max_spare_servers = ${PHP_MAX_SPARE_SERVERS}/" /etc/php/"${PHP_VERSION}"/fpm/pool.d/www.conf

echo "memory_limit = ${PHP_MEMORY_LIMIT}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}
max_input_vars = ${PHP_MAX_INPUT_VARIABLES}
max_input_time = ${PHP_MAX_INPUT_TIME}" > /etc/php/"${PHP_VERSION}"/fpm/conf.d/30-zoneminder.ini

echo "Redirecting PHP Logs to stdout" | info "[${program_name}] "
ln -sf /proc/self/fd/1 /var/log/php"${PHP_VERSION}"-fpm.log
