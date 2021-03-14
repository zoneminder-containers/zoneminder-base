#!/usr/bin/with-contenv bash

echo "[ZoneMinder] Stopping ZoneMinder"
# TODO: Figure out why these logs aren't coming through
/usr/bin/zmpkg.pl stop
