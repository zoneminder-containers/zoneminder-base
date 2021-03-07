# syntax=docker/dockerfile:experimental
FROM debian:buster as base-image

RUN apt-get update \
    && apt-get install -y \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Install ZM Dependencies
# https://github.com/ZoneMinder/zoneminder/blob/8ebaee998aa6b1de0123753a0df86b240235fa33/distros/ubuntu2004/control#L42
# Todo directly install deps using mk-build-deps/find some way to directly parse the control file
RUN apt-get update \
    && apt-get install -y \
        ffmpeg \
        javascript-common \
        libarchive-zip-perl \
        libclass-std-fast-perl \
        libcrypt-eksblowfish-perl \
        libdata-dump-perl \
        libdata-entropy-perl \
        libdata-uuid-perl \
        libdate-manip-perl \
        libdatetime-perl \
        libdbd-mysql-perl \
        libdbd-mysql-perl \
        libdevice-serialport-perl \
        libdigest-sha-perl \
        libfile-slurp-perl \
        libimage-info-perl \
        libio-socket-multicast-perl \
        libjson-maybexs-perl \
        liblivemedia64 \
        libmime-lite-perl \
        libmime-tools-perl \
        libmodule-load-conditional-perl \
        libnet-sftp-foreign-perl \
        libnumber-bytes-human-perl \
        libpcre3 \
        libphp-serialization-perl \
        libsoap-wsdl-perl \
        libswresample3 \
        libswscale5 \
        libsys-cpu-perl \
        libsys-meminfo-perl \
        libsys-mmap-perl \
        liburi-encode-perl \
        liburi-perl \
        libvncclient1 \
        libwww-perl \
        mariadb-client \
        php-apcu \
        php-apcu-bc \
        php-gd \
        php-json \
        php-mysql \
        policykit-1 \
        rsyslog \
        zip \
    && rm -rf /var/lib/apt/lists/*

FROM base-image as builder
WORKDIR /zmbuild

# Skip interactive post-install scripts
ENV DEBIAN_FRONTEND=noninteractive

# Install base toolset
RUN apt-get update \
    && apt-get install -y \
        sudo \
        git \
        cmake \
        build-essential \
        wget

# Install Deps
RUN apt-get update \
    && apt-get install -y \
        cmake \
        debhelper \
        default-libmysqlclient-dev \
        dh-apache2 \
        dh-linktree \
        ffmpeg \
        libavcodec-dev \
        libavdevice-dev \
        libavformat-dev \
        libavutil-dev \
        libbz2-dev \
        libcrypt-eksblowfish-perl \
        libcurl4-gnutls-dev \
        libdata-entropy-perl \
        libdata-uuid-perl \
        libdate-manip-perl \
        libdbd-mysql-perl \
        libgcrypt20-dev \
        libjpeg62-turbo-dev \
        liblivemedia-dev \
        libpcre3-dev \
        libphp-serialization-perl \
        libpolkit-gobject-1-dev \
        libssl-dev \
        libswresample-dev \
        libswscale-dev \
        libsys-mmap-perl \
        libturbojpeg0-dev \
        libv4l-dev \
        libvlc-dev \
        libvncserver-dev \
        libwww-perl \
        net-tools \
        python3-sphinx \
        sphinx-doc

RUN git clone --recursive https://github.com/ZoneMinder/zoneminder.git . \
    && cmake \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_SKIP_RPATH=ON \
        -DCMAKE_VERBOSE_MAKEFILE=OFF \
        -DCMAKE_COLOR_MAKEFILE=ON \
        -DZM_RUNDIR=/var/run/zm \
        -DZM_SOCKDIR=/var/run/zm \
        -DZM_TMPDIR=/var/tmp/zm \
        -DZM_LOGDIR=/var/log/zm \
        -DZM_WEBDIR=/usr/share/zoneminder/www \
        -DZM_CONTENTDIR=/var/cache/zoneminder \
        -DZM_CACHEDIR=/var/cache/zoneminder/cache \
        -DZM_CGIDIR=/usr/lib/zoneminder/cgi-bin \
        -DZM_WEB_USER=www-data \
        -DZM_WEB_GROUP=www-data \
        -DCMAKE_INSTALL_SYSCONFDIR=etc/zm \
        -DZM_CONFIG_DIR=/etc/zm \
        -DCMAKE_BUILD_TYPE=Debug \
        . \
    && make \
    && make DESTDIR="/zminstall" install

FROM base-image as final-build

# Install additional services required by ZM
RUN apt-get update \
    && apt-get install -y \
        apache2 \
        libapache2-mod-php \
        mariadb-server \
        php-fpm \
    && rm -rf /var/lib/apt/lists/*

# Create users
RUN adduser www-data video

# Install ZM
COPY --chown=www-data --chmod=755 --from=builder /zminstall /
COPY --chown=www-data --chmod=755 --from=builder /zmbuild/distros/ubuntu2004/conf/apache2/zoneminder.conf /etc/apache2/conf-available/

# Create required folders
RUN mkdir -p \
        /var/cache/zoneminder/cache \
        /var/cache/zoneminder/events \
        /var/cache/zoneminder/images \
        /var/cache/zoneminder/temp \
        /var/lib/zm \
        /var/log/zm \
    && chown -R www-data:www-data \
        /var/cache/zoneminder \
        /var/lib/zm \
        /var/log/zm \
    && chmod -R 755 \
        /var/cache/zoneminder \
        /var/lib/zm \
        /var/log/zm

# Reconfigure apache
RUN a2enconf zoneminder \
    && a2enmod rewrite

# Configure entrypoint
COPY --chmod=755 entrypoint.sh /usr/local/bin/
CMD ["/usr/local/bin/entrypoint.sh"]