#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"

echo "[ZoneMinder] Stopping ZoneMinder"
# TODO: Figure out why these logs aren't coming through
exec s6-setuidgid www-data /usr/bin/zmpkg.pl stop
