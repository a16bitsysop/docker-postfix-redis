#!/bin/sh
#display environment variables passed with --env
RSPAMD="$RSPAMD"
HOSTNAME="$HOSTNAME"
echo "\$REDIS= $REDIS"
echo "\$HOSTNAME= $HOSTNAME"
echo "\$DOMAIN= $DOMAIN"
echo "\$LETSENCRYPT= $LETSENCRYPT"
echo "\$RSPAMD= $RSPAMD"
echo "\$DOVECOT= $DOVECOT"
NME=postfix-redis
set-timezone.sh "$NME"

echo "Configuring from environment variables"

if [ -n "$REDIS" ]; then
  REDISIP=$(ping -c1 "$REDIS" | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  find /etc/postfix/redis-*.cf -maxdepth 0 -type f -exec sed -e "s+host =.*+host = $REDISIP+g" -i '{}' \;
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

if [ -n "$RSPAMD" ]; then
  RSPAMDIP=$(ping -c1 "$RSPAMD" | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  postconf -e "smtpd_milters = inet:$RSPAMDIP:11332"
  postconf -e "non_smtpd_milters = inet:$RSPAMDIP:11332"
fi

if [ -n "$DOVECOT" ]; then
  DOVEIP=$(ping -c1 "$DOVECOT" | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  postconf -e "virtual_transport = lmtp:inet:$DOVEIP"
  sed -i "s+.*smtpd_sasl_path.*+  -o smtpd_sasl_path=inet:$DOVEIP:11330+g" /etc/postfix/master.cf
fi

cp /etc/resolv.conf /var/spool/postfix/etc/
[ -f /etc/localtime ] && cp /etc/localtime /var/spool/postfix/etc/

postfix set-permissions
postfix start-fg
