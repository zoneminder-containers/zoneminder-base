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

RUN set -x \
    && apk add \
        git \
    && git clone https://github.com/ZoneMinder/zoneminder.git . \
    && git checkout ${ZM_VERSION} \
    && git submodule update --init --recursive

COPY parse.py .

# This parses the control file located at distros/ubuntu2004/control
# It outputs runtime.txt and build.txt with all the dependencies to be
# apt-get installed
RUN set -x \
    && python3 -u parse.py

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
    && wget -O /tmp/s6-overlay.tar.gz "https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${S6_ARCH}.tar.gz" \
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
    && apt-get install -y \
        ca-certificates \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Required for libmp4v2-dev
RUN set -x \
    && echo "deb [trusted=yes] https://zmrepo.zoneminder.com/debian/release-1.34 buster/" >> /etc/apt/sources.list \
    && wget -O - https://zmrepo.zoneminder.com/debian/archive-keyring.gpg | apt-key add -

# Install ZM Dependencies
# https://github.com/ZoneMinder/zoneminder/blob/8ebaee998aa6b1de0123753a0df86b240235fa33/distros/ubuntu2004/control#L42
RUN --mount=type=bind,target=/tmp/runtime.txt,source=/zmsource/runtime.txt,from=zm-source,rw \
    set -x \
    && apt-get update \
    && apt-get install -y \
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
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        build-essential

# Install libjwt since its an optional dep not included in the control file
RUN set -x \
    && apt-get install -y \
        libjwt-dev

# Install Build Dependencies
RUN --mount=type=bind,target=/tmp/build.txt,source=/zmsource/build.txt,from=zm-source,rw \
    set -x \
    && apt-get install -y \
        $(grep -vE "^\s*#" /tmp/build.txt  | tr "\n" " ")

RUN --mount=type=bind,target=/zmbuild,source=/zmsource,from=zm-source,rw \
    set -x \
    && cmake \
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
# PHP-fpm not required for apache
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        apache2 \
        libapache2-mod-php \
        mariadb-server \
        php-fpm \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

## Create www-data user
RUN set -x \
    && groupmod -o -g 911 www-data \
    && usermod -o -u 911 www-data

# Install ZM
COPY --chown=www-data --chmod=755 --from=builder /zminstall /

# Install s6 overlay
COPY --from=s6downloader /s6downloader /

# Create required folders
# Remove content directory create when s6 is implemented
RUN set -x \
    && mkdir -p \
        /zoneminder/run \
        /zoneminder/cache \
        /zoneminder/content \
        /zoneminder/tmp \
        /log \
    && chown -R www-data:www-data \
        /zoneminder \
        /log \
    && chmod -R 755 \
        /zoneminder \
        /log

# Hide index.html
RUN set -x \
    && rm /var/www/html/index.html

# Copy rootfs
COPY root /

# Reconfigure apache
RUN set -x \
    && a2enconf zoneminder \
    && a2enmod rewrite

# Redirect apache logs to stdout
RUN set -x \
    && ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log

LABEL \
    org.opencontainers.image.version=${ZM_VERSION}

ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    S6_KILL_FINISH_MAXTIME=30000

CMD ["/init"]
