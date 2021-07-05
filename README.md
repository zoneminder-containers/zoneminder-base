# Zoneminder Container

[![Docker Build](https://github.com/zoneminder-containers/zoneminder-base/actions/workflows/docker-build.yaml/badge.svg)](https://github.com/zoneminder-containers/eventserver-base/actions/workflows/docker-build.yaml)
[![DockerHub Pulls](https://img.shields.io/docker/pulls/yaoa/zoneminder-base.svg)](https://hub.docker.com/r/yaoa/zoneminder-base)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

# Why
This is an automatically updating ZoneMinder container built using s6-overlay with full support for all things containers.
This aims to be the container that will never die as things will automatically keep themselves up to date and allow for
easy selection/testing of various ZoneMinder versions.

This container aims to follow all of the best practices of being a container meaning that the software and persistent
data are separated, with the container remaining static. This means the container can easily be updated/restored provided
the persistent data volumes are backed up. 

Not only does this aim to follow all of the best practices, but this also aims to be
the easiest container with nearly everything configurable through environment variables
or automatically/preconfigured for you!

There is also full support for multi-server setups with automation to link all servers!

# How

1. Install [Docker](https://docs.docker.com/get-docker/) and [docker-compose](https://docs.docker.com/compose/install/)
2. Download docker-compose.yml or docker-compose-multi.yml depending on single/multi server setups.
3. Download .env
4. Place all these files in the same folder and configure .env and the yml files as you please.
5. Run `docker-compose up -d` to start.

NOTE: The default docker-compose.yml files use the `latest` tag which runs the latest nightly builds of ZoneMinder.
This is the bleeding edge and is not recommended for production!

## Defining a Version

1. Replace `latest` in the `docker-compose.yml` file with any ZoneMinder version you would like to run.
You can find all available releases [here](https://github.com/zoneminder-containers/zoneminder-base/releases).
Ex. `1.36.1`
   
Note: For those new to Docker, these values are known as the container tag.

## Updates

1. Replace the tag with the new version to update to, or for `latest`, simply continue to the next step.
2. `docker-compose pull`
3. `docker-compose up -d`


# Helpful Info
Logs are rotated according to the [TAI64N standard](http://skarnet.org/software/s6/s6-log.html)

`/data` is not included in fix-permissions because it takes a substantial amount of time to run for the events folder
when there are a large number of files

# Issues:
- Tell me?

# Future Containers:

1. [eventserver-base](https://github.com/zoneminder-containers/eventserver-base) (Currently WIP)
  - Install ZM Event Server
  - Automatically enable Event Server and modify Servers table entry to enable Event Server
2. eventserver-mlapi-base
  - Install YOLO ML Models without opencv
3. eventserver-mlapi
  - Build and install standard opencv
4. eventserver-mlapi-cuda
  - Develop autobuilding opencv with cuda support container
