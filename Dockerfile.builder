FROM debian:buster as builder
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

# Required for libmp4v2-dev
RUN echo "deb [trusted=yes] https://zmrepo.zoneminder.com/debian/release-1.34 buster/" >> /etc/apt/sources.list \
    && wget -O - https://zmrepo.zoneminder.com/debian/archive-keyring.gpg | apt-key add -

# Install Deps
RUN apt-get update \
    && apt-get install -y \
        default-libmysqlclient-dev \
        libavdevice-dev \
        libavformat-dev \
        libcurl4-gnutls-dev \
        libdate-manip-perl \
        libdbd-mysql-perl \
        libdbi-perl \
        libdistro-info-perl \
        libgcrypt20-dev \
        libgnutls28-dev \
        libjpeg-dev \
        libjwt-gnutls-dev \
        libmp4v2-dev \
        libpcre3-dev \
        libpolkit-gobject-1-dev \
        libsys-mmap-perl \
        libv4l-dev \
        libvlc-dev \
        libvncserver-dev \
        libx264-dev


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

FROM debian:buster

RUN apt-get update \
    && apt-get install -y \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Required for libmp4v2-dev
RUN echo "deb [trusted=yes] https://zmrepo.zoneminder.com/debian/release-1.34 buster/" >> /etc/apt/sources.list \
    && wget -O - https://zmrepo.zoneminder.com/debian/archive-keyring.gpg | apt-key add -

# Install ZM Dependencies
# https://github.com/ZoneMinder/zoneminder/blob/8a26252914553ac888fe4e9d43419232d37e24d0/distros/debian/control#L36
# https://github.com/ZoneMinder/zoneminder/blob/8a26252914553ac888fe4e9d43419232d37e24d0/distros/ubuntu2004/control#L47
# + some pain and agony, maybe some tears
RUN apt-get update \
    && apt-get install -y \
        apache2 \
        ffmpeg \
        javascript-common \
        libarchive-zip-perl \
        libapache2-mod-php \
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
        libmime-lite-perl \
        libmime-tools-perl \
        libmodule-load-conditional-perl \
        libmp4v2-2 \
        libmp4v2-2 \
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
        libx264-155 \
        mariadb-client \
        mariadb-server \
        perl-modules \
        php-apcu \
        php-apcu-bc \
        php-fpm \
        php-gd \
        php-json \
        php-mysql \
        policykit-1 \
        rsyslog \
        zip \
    && rm -rf /var/lib/apt/lists/*


# Install ZM
COPY --from=builder /zminstall /
COPY --from=builder /zmbuild/distros/ubuntu2004/conf/apache2/zoneminder.conf /etc/apache2/conf-available/

# Create users
RUN adduser www-data video \
    && chown -R www-data:www-data /usr/share/zoneminder/www \
    && chmod -R 755 /usr/share/zoneminder/www

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
COPY entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]