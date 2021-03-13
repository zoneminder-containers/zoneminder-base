# syntax=docker/dockerfile:experimental
ARG ZM_VERSION=master
ARG S6_ARCH=amd64
#####################################################################
#                                                                   #
# Download Zoneminder Source Code                                   #
# Parse control file for all runtime and build dependencies         #
#                                                                   #
#####################################################################
FROM python:alpine as zm-source
ARG ZM_VERSION
WORKDIR /zmsource

RUN apk add \
        git \
    && git clone --recursive -b ${ZM_VERSION} https://github.com/ZoneMinder/zoneminder.git .

COPY parse.py .

# This parses the control file located at distros/ubuntu2004/control
# It outputs runtime.txt and build.txt with all the dependencies to be
# apt-get installed
RUN python3 -u parse.py

#####################################################################
#                                                                   #
# Download and extract s6 overlay                                   #
#                                                                   #
#####################################################################
FROM alpine:latest as s6downloader
# Required to persist build arg
ARG S6_ARCH
WORKDIR /s6downloader

RUN set -x \
    && OVERLAY_VERSION=$(wget --no-check-certificate -qO - https://api.github.com/repos/just-containers/s6-overlay/releases/latest | awk '/tag_name/{print $4;exit}' FS='[""]') \
    && wget -O /tmp/s6-overlay.tar.gz "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.gz" \
    && mkdir -p /tmp/s6 \
    && tar zxvf /tmp/s6-overlay.tar.gz -C /tmp/s6 \
    && mv /tmp/s6/* .

#####################################################################
#                                                                   #
# Install base dependencies                                         #
#                                                                   #
#####################################################################

FROM debian:buster as base-image

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Required for libmp4v2-dev
RUN echo "deb [trusted=yes] https://zmrepo.zoneminder.com/debian/release-1.34 buster/" >> /etc/apt/sources.list \
    && wget -O - https://zmrepo.zoneminder.com/debian/archive-keyring.gpg | apt-key add -

# Install ZM Dependencies
# https://github.com/ZoneMinder/zoneminder/blob/8ebaee998aa6b1de0123753a0df86b240235fa33/distros/ubuntu2004/control#L42
RUN --mount=type=bind,target=/tmp/runtime.txt,source=/zmsource/runtime.txt,from=zm-source,rw \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        $(grep -vE "^\s*#" /tmp/runtime.txt  | tr "\n" " ") \
    && rm -rf /var/lib/apt/lists/*

#####################################################################
#                                                                   #
# Install build dependencies and build ZoneMinder                   #
#                                                                   #
#####################################################################

FROM base-image as builder
WORKDIR /zmbuild

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

# Install base toolset
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential

# Install Build Dependencies
RUN --mount=type=bind,target=/tmp/build.txt,source=/zmsource/build.txt,from=zm-source,rw \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        $(grep -vE "^\s*#" /tmp/build.txt  | tr "\n" " ")

RUN --mount=type=bind,target=/zmbuild,source=/zmsource,from=zm-source,rw \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_SKIP_RPATH=ON \
        -DCMAKE_VERBOSE_MAKEFILE=OFF \
        -DCMAKE_COLOR_MAKEFILE=ON \
        -DZM_RUNDIR=/zoneminder/run \
        -DZM_SOCKDIR=/zoneminder/run \
        -DZM_TMPDIR=/zoneminder/tmp \
        -DZM_LOGDIR=/log \
        -DZM_WEBDIR=/var/www/html \
        -DZM_CONTENTDIR=/zoneminder/content \
        -DZM_CACHEDIR=/zoneminder/cache \
        -DZM_CGIDIR=/zoneminder/cgi-bin \
        -DZM_WEB_USER=www-data \
        -DZM_WEB_GROUP=www-data \
        -DCMAKE_INSTALL_SYSCONFDIR=config \
        -DZM_CONFIG_DIR=/zoneminder/config \
        -DCMAKE_BUILD_TYPE=Debug \
        . \
    && make \
    && make DESTDIR="/zminstall" install

#####################################################################
#                                                                   #
# Install ZoneMinder                                                #
# Create required folders                                           #
# Install additional dependencies                                   #
#                                                                   #
#####################################################################

FROM base-image as final-build
ARG ZM_VERSION

# Install additional services required by ZM
# Remove file install after switch to s6
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apache2 \
        file \
        libapache2-mod-php \
        mariadb-server \
        php-fpm \
    && rm -rf /var/lib/apt/lists/*

# Create users
RUN adduser www-data video

# Install ZM
COPY --chown=www-data --chmod=755 --from=builder /zminstall /

# Install s6 overlay
COPY --from=s6downloader /s6downloader /

# Create required folders
# Remove content directory create when s6 is implemented
RUN mkdir -p \
        /zoneminder/run \
        /zoneminder/cache \
        /zoneminder/content/events \
        /zoneminder/content/images \
        /zoneminder/tmp \
        /log \
    && chown -R www-data:www-data \
        /zoneminder \
        /log \
    && chmod -R 755 \
        /zoneminder \
        /log

# Hide index.html
RUN rm /var/www/html/index.html

# Copy rootfs
COPY root /

# Reconfigure apache
RUN a2enconf zoneminder \
    && a2enmod rewrite

# Configure entrypoint
COPY --chmod=755 entrypoint.sh /usr/local/bin/

LABEL \
    org.opencontainers.image.version=${ZM_VERSION}

CMD ["/usr/local/bin/entrypoint.sh"]
