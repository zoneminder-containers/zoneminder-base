#!/usr/bin/with-contenv bash

echo "Stopping Apache2"
exec /usr/sbin/apachectl -k graceful-stop
