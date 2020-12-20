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
RUN apt-get update \
    && apt-get install -y \
        gnupg \
        apt-transport-https \
        wget \
        ca-certificates \
        apache2 \
        apache2-bin \
        apache2-data \
        apache2-utils \
        bsd-mailx \
        cron \
        dmsetup \
        docutils-common \
        docutils-doc \
        exim4-base \
        exim4-config \
        exim4-daemon-light \
        ffmpeg \
        fonts-font-awesome \
        fonts-lato \
        fonts-roboto-slab \
        galera-3 \
        gawk \
        javascript-common \
        libaio1 \
        libalgorithm-c3-perl \
        libapache2-mod-php \
        libapache2-mod-php7.3 \
        libappconfig-perl \
        libapr1 \
        libaprutil1 \
        libaprutil1-dbd-sqlite3 \
        libaprutil1-ldap \
        libarchive-zip-perl \
        libargon2-1 \
        libauthen-sasl-perl \
        libavresample4 \
        libb-hooks-endofscope-perl \
        libb-hooks-op-check-perl \
        libbrotli1 \
        libcgi-fast-perl \
        libcgi-pm-perl \
        libclass-c3-perl \
        libclass-c3-xs-perl \
        libclass-data-inheritable-perl \
        libclass-inspector-perl \
        libclass-load-perl \
        libclass-method-modifiers-perl \
        libclass-mix-perl \
        libclass-singleton-perl \
        libclass-std-fast-perl \
        libclass-std-perl \
        libclass-xsaccessor-perl \
        libconfig-inifiles-perl \
        libconvert-binhex-perl \
        libcpanel-json-xs-perl \
        libcrypt-eksblowfish-perl \
        libcrypt-rijndael-perl \
        libcryptsetup12 \
        libdata-dump-perl \
        libdata-entropy-perl \
        libdata-float-perl \
        libdata-optlist-perl \
        libdatetime-locale-perl \
        libdatetime-perl \
        libdatetime-timezone-perl \
        libdevel-callchecker-perl \
        libdevel-caller-perl \
        libdevel-lexalias-perl \
        libdevel-stacktrace-perl \
        libdevice-serialport-perl \
        libdevmapper1.02.1 \
        libdynaloader-functions-perl \
        libemail-date-format-perl \
        libencode-locale-perl \
        libestr0 \
        libeval-closure-perl \
        libexception-class-perl \
        libfastjson4 \
        libfcgi-perl \
        libfile-listing-perl \
        libfile-sharedir-perl \
        libfile-slurp-perl \
        libfont-afm-perl \
        libgd3 \
        libhtml-form-perl \
        libhtml-format-perl \
        libhtml-parser-perl \
        libhtml-tagset-perl \
        libhtml-template-perl \
        libhtml-tree-perl \
        libhttp-cookies-perl \
        libhttp-daemon-perl \
        libhttp-date-perl \
        libhttp-lite-perl \
        libhttp-message-perl \
        libhttp-negotiate-perl \
        libimage-base-bundle-perl \
        libimage-info-perl \
        libimagequant0 \
        libio-html-perl \
        libio-interface-perl \
        libio-pty-perl \
        libio-sessiondata-perl \
        libio-socket-multicast-perl \
        libio-socket-ssl-perl \
        libio-string-perl \
        libio-stringy-perl \
        libip4tc0 \
        libjs-jquery \
        libjs-modernizr \
        libjs-mootools \
        libjs-sphinxdoc \
        libjs-underscore \
        libjson-c3 \
        libjson-maybexs-perl \
        libkmod2 \
        liblcms2-2 \
        liblockfile-bin \
        liblockfile1 \
        liblognorm5 \
        liblua5.2-0 \
        liblwp-mediatypes-perl \
        liblwp-protocol-https-perl \
        libmailtools-perl \
        libmime-lite-perl \
        libmime-tools-perl \
        libmime-types-perl \
        libmodule-implementation-perl \
        libmodule-runtime-perl \
        libmro-compat-perl \
        libmp4v2-2 \
        libnamespace-autoclean-perl \
        libnamespace-clean-perl \
        libnet-http-perl \
        libnet-libidn-perl \
        libnet-sftp-foreign-perl \
        libnet-smtp-ssl-perl \
        libnet-ssleay-perl \
        libnss-systemd \
        libnumber-bytes-human-perl \
        libossp-uuid-perl \
        libossp-uuid16 \
        libpackage-stash-perl \
        libpackage-stash-xs-perl \
        libpadwalker-perl \
        libpam-systemd \
        libpaper-utils \
        libpaper1 \
        libparams-classify-perl \
        libparams-util-perl \
        libparams-validationcompiler-perl \
        libphp-serialization-perl \
        libpolkit-backend-1-0 \
        libpopt0 \
        libpython-stdlib \
        libpython2-stdlib \
        libpython2.7-minimal \
        libpython2.7-stdlib \
        libreadline5 \
        libreadonly-perl \
        libref-util-perl \
        libref-util-xs-perl \
        librole-tiny-perl \
        libsigsegv2 \
        libsoap-lite-perl \
        libsoap-wsdl-perl \
        libspecio-perl \
        libsub-exporter-perl \
        libsub-exporter-progressive-perl \
        libsub-identify-perl \
        libsub-install-perl \
        libsub-name-perl \
        libsub-quote-perl \
        libsys-cpu-perl \
        libsys-meminfo-perl \
        libtask-weaken-perl \
        libtemplate-perl \
        libterm-readkey-perl \
        libtimedate-perl \
        libtry-tiny-perl \
        liburi-encode-perl \
        liburi-perl \
        libvariable-magic-perl \
        libwebpdemux2 \
        libwww-perl \
        libwww-robotrules-perl \
        libxml-libxml-perl \
        libxml-namespacesupport-perl \
        libxml-parser-perl \
        libxml-sax-base-perl \
        libxml-sax-expat-perl \
        libxml-sax-perl \
        libxmlrpc-lite-perl \
        libxpm4 \
        logrotate \
        lsof \
        mariadb-client \
        mariadb-client-10.3 \
        mariadb-client-core-10.3 \
        mariadb-server \
        mariadb-server-10.3 \
        mariadb-server-core-10.3 \
        perl-openssl-defaults \
        php-apcu \
        php-apcu-bc \
        php-common \
        php-gd \
        php-mysql \
        php7.3-cli \
        php7.3-common \
        php7.3-gd \
        php7.3-json \
        php7.3-mysql \
        php7.3-opcache \
        php7.3-phpdbg \
        php7.3-readline \
        policykit-1 \
        python \
        python-alabaster \
        python-asn1crypto \
        python-babel \
        python-babel-localedata \
        python-certifi \
        python-cffi-backend \
        python-chardet \
        python-cryptography \
        python-docutils \
        python-enum34 \
        python-idna \
        python-imagesize \
        python-ipaddress \
        python-jinja2 \
        python-markupsafe \
        python-minimal \
        python-olefile \
        python-openssl \
        python-packaging \
        python-pil \
        python-pkg-resources \
        python-pygments \
        python-pyparsing \
        python-requests \
        python-roman \
        python-six \
        python-sphinx \
        python-sphinx-rtd-theme \
        python-typing \
        python-tz \
        python-urllib3 \
        python2 \
        python2-minimal \
        python2.7 \
        python2.7-minimal \
        rsync \
        rsyslog \
        sgml-base \
        socat \
        sphinx-common \
        sphinx-rtd-theme-common \
        ssl-cert \
        systemd \
        systemd-sysv \
        unzip \
        xml-core \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Install ZM
COPY --from=builder /zminstall /
COPY --from=builder /zmbuild/distros/ubuntu2004/conf/apache2/zoneminder.conf /etc/apache2/conf-available/

RUN adduser www-data video \
    && a2enconf zoneminder \
    && a2enmod rewrite

# Configure entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]