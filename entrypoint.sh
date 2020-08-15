#!/bin/sh
#display environment variables passed with --env
echo '$REDIS=' $REDIS
echo '$HOSTNAME=' $HOSTANAME
echo '$DOMAIN=' $DOMAIN
echo '$LETSENCRYPT=' $LETSENCRYPT
echo '$POSTMASTER=' $POSTMASTER
echo '$RSPAMD=' $RSPAMD
echo '$DOVECOT=' $DOVECOT

#NME=postfix-redis
#set-timezone.sh "$NME"

echo "Configuring from environment variables"

if [ -n "$REDIS" ]; then
  REDISIP=$(ping -c1 $REDIS | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  sed -e "s+host =.*+host = "$REDISIP"+g" -i /etc/postfix/redis-vdomains.cf
  sed -e "s+host =.*+host = "$REDISIP"+g" -i /etc/postfix/redis-vmailbox-maps.cf
  sed -e "s+host =.*+host = "$REDISIP"+g" -i /etc/postfix/redis-valias-maps.cf
  sed -e "s+host =.*+host = "$REDISIP"+g" -i /etc/postfix/redis-alias.cf
  sed -e "s+host =.*+host = "$REDISIP"+g" -i /etc/postfix/redis-postscreen.cf
fi

if [ -n "$DOMAIN" ]; then
  postconf -e "myorigin = $DOMAIN"
fi

if [ -n "$HOSTNAME" ]; then
  postconf -e "myhostname = $HOSTNAME"
  if [ -n "$LETSENCRYPT" ]; then
    postconf -e "smtpd_tls_cert_file=/etc/letsencrypt/live/$LETSENCRYPT/fullchain.pem"
    postconf -e "smtpd_tls_key_file=/etc/letsencrypt/live/$LETSENCRYPT/privkey.pem"
  fi
fi

if [ -n "$POSTMASTER" ]; then
  sed -i "s+root:.*+root: $POSTMASTER+g" /etc/aliases
fi

if [ -n "$RSPAMD" ]; then
  RSPAMDIP=$(ping -c1 $RSPAMD | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  postconf -e "smtpd_milters = inet:$RSPAMDIP:11332"
  postconf -e "non_smtpd_milters = inet:$RSPAMDIP:11332"
fi

[ -n "$DOVECOT" ] && postconf -e "virtual_transport = lmtp:inet:$DOVECOT"

newaliases

/usr/sbin/postfix start-fg
