#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"
program_name="first-run-check"

if [ ! -f "/config/zm.conf" ] && [ ! -d "/data/events" ]; then
  echo "Detected this startup as the first run of this container. Initializing first run scripts..." | init "${program_name}"
  echo -n "1" > /var/run/s6/container_environment/ZM_FIRST_RUN
fi
