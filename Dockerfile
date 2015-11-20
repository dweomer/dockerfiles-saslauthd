FROM alpine:3.2

MAINTAINER Jacob Blain Christen <mailto:dweomer5@gmail.com, https://github.com/dweomer, https://twitter.com/dweomer>

ENV CYRUS_SASL_VERSION=2.1.26 \
    TINI_VERSION=0.8.3

RUN set -x \
 && mkdir -p /srv/saslauthd.d /tmp/cyrus-sasl /var/run/saslauthd \
 && export BUILD_DEPS=" \
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
        openldap-dev \
        openssl-dev \
        tar \
    " \
 && apk add --update ${BUILD_DEPS} \
        cyrus-sasl \
        libldap \
# Install tini
 && curl -fSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini \
 && chmod +x /bin/tini \
# Install cyrus-sasl from source
 && curl -fL ftp://ftp.cyrusimap.org/cyrus-sasl/cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz -o /tmp/cyrus-sasl.tgz \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.25-avoid_pic_overwrite.patch?h=3.2-stable -o /tmp/cyrus-sasl-2.1.25-avoid_pic_overwrite.patch \
 && curl -fL http://git.alpinelinux.org/cgit/aports/plain/main/cyrus-sasl/cyrus-sasl-2.1.26-size_t.patch?h=3.2-stable -o /tmp/cyrus-sasl-2.1.26-size_t.patch \
 && tar -xzf /tmp/cyrus-sasl.tgz --strip=1 -C /tmp/cyrus-sasl \
 && cd /tmp/cyrus-sasl \
 && patch -p1 -i /tmp/cyrus-sasl-2.1.25-avoid_pic_overwrite.patch || true \
 && patch -p1 -i /tmp/cyrus-sasl-2.1.26-size_t.patch || true \
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
 && apk del --purge ${BUILD_DEPS} \
# Clean up anything else
 && rm -fr \
    /tmp/* \
    /var/tmp/* \
    /var/cache/apk/*

VOLUME ["/var/run/saslauthd"]

ENTRYPOINT ["/bin/tini", "--", "/usr/sbin/saslauthd"]
CMD ["-a", "ldap", "-d", "1"]
