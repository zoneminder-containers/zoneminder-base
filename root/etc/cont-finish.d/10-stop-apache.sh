#!/usr/bin/with-contenv bash
. "/usr/local/bin/logger"

echo "[Apache2] Stopping Apache2"
# TODO: Figure out why these logs aren't coming through
exec /usr/sbin/apachectl -k graceful-stop
