FROM alpine:3.12
LABEL maintainer "Duncan Bellamy <dunk@denkimushi.com>"

COPY packages /tmp/
RUN echo '/tmp/working' >> /etc/apk/repositories \
&& apk add --allow-untrusted ca-certificates openssl postfix postfix-redis \
&& rm -rf /tmp/*

WORKDIR /etc/postfix
COPY conf.d/* ./

WORKDIR /etc
COPY aliases .

WORKDIR /usr/local/bin
COPY entrypoint.sh ./
ENTRYPOINT [ "entrypoint.sh" ]

EXPOSE 25 587
VOLUME [ "/var/lib/postfix" ]
