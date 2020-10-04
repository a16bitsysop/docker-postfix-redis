FROM alpine:edge as builder

WORKDIR /tmp
COPY pull-patch.sh /usr/local/bin
COPY APKBUILD.patch ./
COPY newfiles/* ./newfiles/
COPT postfix/* ./postfix/
RUN apk add --update-cache alpine-conf alpine-sdk sudo \
&& apk upgrade -a
RUN adduser -D builduser \
&& addgroup builduser abuild \
&& echo 'builduser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /home/builduser
RUN cp -a /tmp/* . \
&& pull-patch.sh main/postfix \
&& chown builduser:builduser aport 

USER builduser
RUN abuild-keygen -a -i -n \
&& cd aport \
&& abuild checksum \
&& abuild -r

FROM alpine:3.12
LABEL maintainer "Duncan Bellamy <dunk@denkimushi.com>"

COPY --from=builder /home/builduser/packages/* /tmp/packages/

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
&& wget https://raw.githubusercontent.com/internetstandards/dhe_groups/master/ffdhe2048.pem

WORKDIR /usr/local/bin
COPY travis-helpers/set-timezone.sh entrypoint.sh ./
ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 25 587
VOLUME [ "/var/lib/postfix" ]
