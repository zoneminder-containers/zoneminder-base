#!/command/with-contenv bash
. "/usr/local/bin/logger"
program_name="log-config"

echo "Configuring log rotation with a maximum of ${MAX_LOG_NUMBER} logs and a max log size of ${MAX_LOG_SIZE_BYTES} bytes" | info "[${program_name}] "
echo -n "1 n${MAX_LOG_NUMBER} s${MAX_LOG_SIZE_BYTES}" > /run/s6/container_environment/S6_LOGGING_SCRIPT
