ARG ALPVER=3.14
FROM alpine:${ALPVER} as builder

WORKDIR /tmp
COPY travis-helpers/build-apk-native.sh travis-helpers/pull-apk-source.sh /usr/local/bin/
COPY APKBUILD.patch ./
COPY newfiles/* ./newfiles/

RUN build-apk-native.sh main/postfix

FROM alpine:${ALPVER}
LABEL maintainer="Duncan Bellamy <dunk@denkimushi.com>"

COPY --from=builder /tmp/packages/* /tmp/packages/

# hadolint ignore=DL3018
RUN cp /etc/apk/repositories /etc/apk/repositories.orig \
&& echo '/tmp/packages' >> /etc/apk/repositories \
&& chown -R root:root /tmp/packages \
&& apk add -u --no-cache --allow-untrusted ca-certificates openssl postfix postfix-redis stunnel \
&& mkdir /var/spool/postfix/etc \
&& cp  /etc/services /var/spool/postfix/etc/services \
&& rm -rf /tmp/* \
&& newaliases \
&& mv /etc/apk/repositories.orig /etc/apk/repositories

WORKDIR /etc/postfix
COPY conf.d/* ./
RUN wget -q https://raw.githubusercontent.com/internetstandards/dhe_groups/master/ffdhe4096.pem \
&& wget -q https://raw.githubusercontent.com/internetstandards/dhe_groups/master/ffdhe2048.pem

WORKDIR /usr/local/bin
COPY travis-helpers/set-timezone.sh entrypoint.sh ./
COPY stunnel.conf /etc/stunnel/stunnel.conf

ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 25 587
VOLUME [ "/var/lib/postfix" ]
