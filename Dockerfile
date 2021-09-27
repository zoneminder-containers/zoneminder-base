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
    && git submodule update --init --recursive \
    && git checkout ${ZM_VERSION} \
    && git submodule update --init --recursive

COPY parse_control.py .

# This parses the control file located at distros/ubuntu2004/control
# It outputs zoneminder_control which only includes requirements for zoneminder
# This prevents equivs-build from being confused when there are multiple packages
RUN set -x \
    && python3 -u parse_control.py

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
    && cp -r /tmp/s6/* .

RUN set -x \
    && wget -O /tmp/socklog-overlay.tar.gz "https://github.com/just-containers/socklog-overlay/releases/latest/download/socklog-overlay-${S6_ARCH}.tar.gz" \
    && mkdir -p /tmp/socklog \
    && tar zxvf /tmp/socklog-overlay.tar.gz -C /tmp/socklog \
    && cp -r /tmp/socklog/* .

#####################################################################
#                                                                   #
# Prepare base-image with core programs + repository                #
#                                                                   #
#####################################################################
FROM debian:bullseye as base-image-core

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        ca-certificates \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

#####################################################################
#                                                                   #
# Build packages containing build and runtime dependencies          #
# for installation in later stages                                  #
#                                                                   #
#####################################################################
FROM base-image-core as package-builder
WORKDIR /packages

# Install base toolset
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        devscripts

COPY --from=zm-source /zmsource/zoneminder_control /tmp/control

# Create runtime package
RUN --mount=type=bind,target=/usr/share/equivs/template/debian/compat,source=/zmsource/zoneminder_compat,from=zm-source,rw \
    set -x \
    && equivs-build /tmp/control \
    && ls | grep -P \(zoneminder_\)\(.*\)\(\.deb\) | xargs -I {} mv {} runtime-deps.deb

# Create build-deps package
RUN set -x \
    && mk-build-deps /tmp/control \
    && ls | grep -P \(build-deps\)\(.*\)\(\.deb\) | xargs -I {} mv {} build-deps.deb

#####################################################################
#                                                                   #
# Install runtime dependencies                                      #
# Does not include shared lib dependencies as those are resolved    #
# after building. Installed in final-image                          #
#                                                                   #
#####################################################################
FROM base-image-core as base-image

# Install ZM Dependencies
# Don't want recommends of ZM
RUN --mount=type=bind,target=/tmp/runtime-deps.deb,source=/packages/runtime-deps.deb,from=package-builder,rw \
    set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ./tmp/runtime-deps.deb \
    && rm -rf /var/lib/apt/lists/*

# Remove "zoneminder" shim package from runtime-deps.deb and
# set all runtime dependencies installed by package to manually installed
# Allows removing individual packages without including all packages in autoremove
RUN set -x \
    && apt-get -y remove zoneminder \
    && apt-mark manual $(apt-get -s autoremove 2>/dev/null | awk '/^Remv / { print $2 }')

#####################################################################
#                                                                   #
# Install runtime + build dependencies                              #
# Build Zoneminder                                                  #
#                                                                   #
#####################################################################
FROM package-builder as builder
WORKDIR /zmbuild
# Yes WORKDIR is overwritten but this is more a comment
# to specify the final WORKDIR

# Install ZM Buid and Runtime Dependencies
# Need to install runtime dependencies here as well
# because we don't want devscripts in the base-image
# This results in runtime dependencies being installed twice to avoid additional bloating
WORKDIR /packages
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        ./runtime-deps.deb \
        ./build-deps.deb

WORKDIR /zmbuild
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
        -DZM_LOGDIR=/zoneminder/logs \
        -DZM_WEBDIR=/var/www/html \
        -DZM_CONTENTDIR=/data \
        -DZM_CACHEDIR=/zoneminder/cache \
        -DZM_CGIDIR=/zoneminder/cgi-bin \
        -DZM_WEB_USER=www-data \
        -DZM_WEB_GROUP=www-data \
        -DCMAKE_INSTALL_SYSCONFDIR=config \
        -DZM_CONFIG_DIR=/config \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        . \
    && make \
    && make DESTDIR="/zminstall" install

# Move default config location
RUN set -x \
    && mv /zminstall/config /zminstall/zoneminder/defaultconfig

#####################################################################
#                                                                   #
# Install ZoneMinder                                                #
# Create required folders                                           #
# Install additional dependencies                                   #
#                                                                   #
#####################################################################
FROM base-image as final-build
ARG ZM_VERSION

# Add Nginx Repo
RUN set -x \
    && echo "deb https://nginx.org/packages/mainline/debian/ bullseye nginx" > /etc/apt/sources.list.d/nginx.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62

# Install additional services required by ZM ("Recommends")
# PHP-fpm not required for apache
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        fcgiwrap \
        mailutils \
        msmtp \
        nginx \
        php-fpm \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

# Remove rsyslog as its unneeded and hangs the container on shutdown
RUN set -x \
    && apt-get -y remove rsyslog || true

## Create www-data user
RUN set -x \
    && groupmod -o -g 911 www-data \
    && usermod -o -u 911 www-data

# Install ZM
COPY --chown=www-data --chmod=755 --from=builder /zminstall /

# Install s6 overlay
COPY --from=s6downloader /s6downloader /

# Copy rootfs
COPY rootfs /

# Create required folders
RUN set -x \
    && mkdir -p \
        /run/php \
        /data \
        /config \
        /zoneminder/run \
        /zoneminder/cache \
        /zoneminder/logs \
        /zoneminder/tmp \
        /log \
    && chown -R www-data:www-data \
        /data \
        /config \
        /zoneminder \
    && chmod -R 755 \
        /data \
        /config \
        /zoneminder \
        /log \
    && chown -R nobody:nogroup \
        /log

# Reconfigure nginx and php logs
# Configure msmtp
RUN set -x \
    && ln -sf /proc/self/fd/1 /var/log/nginx/access.log \
    && ln -sf /proc/self/fd/1 /var/log/nginx/error.log \
    && ln -sf /usr/bin/msmtp /usr/lib/sendmail \
    && ln -sf /usr/bin/msmtp /usr/sbin/sendmail \
    && rm -rf /etc/nginx/conf.d

LABEL \
    com.github.alexyao2015.zoneminder_version=${ZM_VERSION}

# System Variables
ENV \
    S6_FIX_ATTRS_HIDDEN=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    SOCKLOG_TIMESTAMP_FORMAT="" \
    MAX_LOG_SIZE_BYTES=1000000 \
    MAX_LOG_NUMBER=10

# Default User Variables
ENV \
    MYSQL_HOST=db \
    PHP_MAX_CHILDREN=120 \
    PHP_START_SERVERS=12 \
    PHP_MIN_SPARE_SERVERS=6 \
    PHP_MAX_SPARE_SERVERS=18 \
    PHP_MEMORY_LIMIT=2048M \
    PHP_MAX_EXECUTION_TIME=600 \
    PHP_MAX_INPUT_VARIABLES=3000 \
    PHP_MAX_INPUT_TIME=600 \
    FCGIWRAP_PROCESSES=15 \
    FASTCGI_BUFFERS_CONFIGURATION_STRING="64 4K" \
    PUID=911 \
    PGID=911 \
    TZ="America/Chicago" \
    USE_SECURE_RANDOM_ORG=1

CMD ["/init"]
