#!/usr/bin/with-contenv bash

echo "[Apache2] Stopping Apache2"
# TODO: Figure out why these logs aren't coming through
exec /usr/sbin/apachectl -k graceful-stop
