FROM alpine:3.2

MAINTAINER Jacob Blain Christen <mailto:dweomer5@gmail.com, https://github.com/dweomer, https://twitter.com/dweomer>

ENV CYRUS_SASL_VERSION=2.1.26 \
    TINI_VERSION=0.8.3

RUN set -x \
 && mkdir -p /srv/saslauthd.d /tmp/cyrus-sasl /var/run/saslauthd \
 && apk add --update \
        autoconf \
        automake \
        db-dev \
        curl \
        cyrus-sasl \
        g++ \
        gcc \
        gzip \
        heimdal-dev \
        libtool \
        make \
        openldap-dev \
        openssl-dev \
        tar \
# Install tini
 && curl -fSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini \
 && chmod +x /bin/tini \
# Install cyrus-sasl from source
 && curl -fL ftp://ftp.cyrusimap.org/cyrus-sasl/cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz -o /tmp/cyrus-sasl.tgz \
 && tar -xzf /tmp/cyrus-sasl.tgz --strip=1 -C /tmp/cyrus-sasl \
 && cd /tmp/cyrus-sasl \
# && sed 's/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/' -i configure.in \
# && rm -rvf \
#        config/config.guess \
#        config/config.sub \
#        config/ltconfig \
#        config/ltmain.sh \
#        config/libtool.m4 \
#        autom4te.cache \
# && libtoolize -c \
# && aclocal -I config -I cmulocal \
# && automake -a -c \
# && autoheader \
# && autoconf \
 && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-anon \
        --enable-cram \
        --enable-digest \
        --enable-ldapdb \
        --enable-login \
        --enable-ntlm \
        --disable-otp \
        --enable-plain \
        --with-gss_impl=heimdal \
        --with-devrandom=/dev/urandom \
        --with-ldap=/usr \
        --with-saslauthd=/var/run/saslauthd \
        --mandir=/usr/share/man \
 && make -j1 \
 && make -j1 install \
# Clean up build-time packages
 && apk del --purge \
        autoconf \
        automake \
        curl \
        db-dev \
        g++ \
        gcc \
        gzip \
        heimdal-dev \
        libtool \
        make \
        tar \
# Clean up anything else
 && rm -fr \
    /tmp/* \
    /var/tmp/* \
    /var/cache/apk/*

VOLUME ["/var/run/saslauthd"]

ENTRYPOINT ["/bin/tini", "--", "/usr/sbin/saslauthd"]
CMD ["-a", "ldap", "-d", "1"]
