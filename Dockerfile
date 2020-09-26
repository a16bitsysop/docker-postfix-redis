FROM alpine:edge as builder
COPY travis-helpers/build-apk-native.sh APKBUILD.patch /tmp/
COPY newfiles/* /tmp/newfiles/
RUN cd /tmp \
&& ./build-apk-native.sh main/postfix


FROM alpine:3.12
LABEL maintainer "Duncan Bellamy <dunk@denkimushi.com>"

COPY --from=builder /tmp/packages/* /tmp/packages/

RUN cp /etc/apk/repositories /etc/apk/repositories.orig \
&& sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories \
&& echo '/tmp/packages' >> /etc/apk/repositories \
&& chown -R root:root /tmp/packages \
&& apk add --no-cache --allow-untrusted ca-certificates openssl postfix postfix-redis \
&& mkdir /var/spool/postfix/etc \
&& cp  /etc/services /var/spool/postfix/etc/services \
&& rm -rf /tmp/* \
&& newaliases \
&& mv /etc/apk/repositories.orig /etc/apk/repositories

WORKDIR /etc/postfix
COPY conf.d/* ./
RUN wget https://raw.githubusercontent.com/internetstandards/dhe_groups/master/ffdhe4096.pem \
&& wget https://raw.githubusercontent.com/internetstandards/dhe_groups/master/ffdhe3072.pem

WORKDIR /usr/local/bin
COPY travis-helpers/set-timezone.sh entrypoint.sh ./
ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 25 587
VOLUME [ "/var/lib/postfix" ]
