FROM alpine:3.12
LABEL maintainer "Duncan Bellamy <dunk@denkimushi.com>"

COPY packages /tmp/
RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories \ 
&& echo '/tmp/working' >> /etc/apk/repositories \
&& apk add --no-cache --allow-untrusted ca-certificates openssl postfix postfix-lmdb postfix-redis \
&& mkdir /var/spool/postfix/etc \
&& cp  /etc/services /var/spool/postfix/etc/services \
&& rm -rf /tmp/* 
#&& newaliases

WORKDIR /etc/postfix
COPY conf.d/* ./

WORKDIR /usr/local/bin
COPY travis-helpers/set-timezone.sh entrypoint.sh ./
ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 25 587
VOLUME [ "/var/lib/postfix" ]
