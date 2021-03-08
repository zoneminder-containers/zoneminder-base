#!/bin/bash

if [ ! -f "/zoneminder/config/zm.conf" ]; then
  echo "Configuring ZoneMinder Configuration for First Run"
  cp -r /zoneminder/config /config
fi

ln -sf /config /zoneminder/config

if [ ! -d "/data" ]; then
  echo "Configuring ZoneMinder Data folder for First Run"
  mkdir -p \
    /data/events \
    /data/images
fi

ln -sf /data /zoneminder/content
