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
echo "\$STUNNEL= $STUNNEL"
NME=postfix-redis
set-timezone.sh "$NME"

echo "Configuring from environment variables"

wait_port() {
  TL=0
  INC=3
  [ -n "$4" ] && INC="$4"
  echo "Waiting for $1"
  while true
  do
    nc -zv "$2" "$3" && return
    echo "."
    TL=$((TL + INC))
    [ "$TL" -gt 90 ] && return 1
    sleep "$INC"
  done
}

if [ -n "$STUNNEL" ]
then
	sed -r "s/(connect =\s).*:/\1$REDIS:/" -i /etc/stunnel/stunnel.conf
	stunnel /etc/stunnel/stunnel.conf
	REDIS="127.0.0.1"
fi

if [ -n "$REDIS" ]
then
  echo "Waiting for redis to load database"
  _ready=""
  while [ -z "$_ready" ]
  do
    sleep 5s
    _reply=$(echo "PING" | nc "$REDIS" 6379)
    echo "$_reply"
    echo "$_reply" | grep "PONG" && _ready="1"
  done

  REDISIP=$(ping -c1 "$REDIS" | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  find /etc/postfix/redis-*.cf -maxdepth 0 -type f -exec sed -e "s+host =.*+host = $REDISIP+g" -i '{}' \;
fi

if [ -n "$DOMAIN" ]
then
  postconf -e "myorigin = $DOMAIN"
fi

if [ -n "$HOSTNAME" ]
then
  postconf -e "myhostname = $HOSTNAME"
  if [ -n "$LETSENCRYPT" ]
  then
    postconf -e "smtpd_tls_chain_files=/etc/letsencrypt/live/$LETSENCRYPT/privkey.pem, /etc/letsencrypt/live/$LETSENCRYPT/fullchain.pem"
  fi
fi

if [ -n "$RSPAMD" ]
then
  wait_port "rspamd" "$RSPAMD" 11332
  RSPAMDIP=$(ping -c1 "$RSPAMD" | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  postconf -e "smtpd_milters = inet:$RSPAMDIP:11332"
  postconf -e "non_smtpd_milters = inet:$RSPAMDIP:11332"
fi

if [ -n "$DOVECOT" ]
then
  DOVEIP=$(ping -c1 "$DOVECOT" | head -n1 | cut -f2 -d'(' | cut -f1 -d')')
  postconf -e "virtual_transport = lmtp:inet:$DOVEIP"
  sed -i "s+.*smtpd_sasl_path.*+  -o smtpd_sasl_path=inet:$DOVEIP:11330+g" /etc/postfix/master.cf
fi

cp /etc/resolv.conf /var/spool/postfix/etc/
[ -f /etc/localtime ] && cp /etc/localtime /var/spool/postfix/etc/

postfix set-permissions
postfix start-fg
