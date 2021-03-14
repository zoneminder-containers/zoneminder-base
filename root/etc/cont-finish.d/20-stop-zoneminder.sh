#!/usr/bin/with-contenv bash

echo "Stopping ZoneMinder"
exec /usr/bin/zmpkg.pl stop
