# docker-postfix-redis
Dockerfile to run [postfix](https://www.postfix.org) as a docker container, redis is used for table lookups to reduce footprint.

[![Docker Pulls](https://img.shields.io/docker/pulls/a16bitsysop/postfix-redis.svg?style=flat-square)](https://hub.docker.com/r/a16bitsysop/postfix-redis/)
[![Docker Stars](https://img.shields.io/docker/stars/a16bitsysop/postfix-redis.svg?style=flat-square)](https://hub.docker.com/r/a16bitsysop/postfix-redis/)
[![Version](https://images.microbadger.com/badges/version/a16bitsysop/postfix-redis.svg)](https://microbadger.com/images/a16bitsysop/postfix-redis "Get your own version badge on microbadger.com")
[![Commit](https://images.microbadger.com/badges/commit/a16bitsysop/postfix-redis.svg)](https://microbadger.com/images/a16bitsysop/postfix-redis "Get your own commit badge on microbadger.com")
[![GitHub Super-Linter](https://github.com/a16bitsysop/docker-postfix-redis/workflows/Super-Linter/badge.svg)](https://github.com/marketplace/actions/super-linter)

Compiles postfix-redis (and postfix) during container creation for easy development and testing.

It uses inet lmtp with ssl and auth, for communicating with dovecot instead of sockets as running inside docker network so less dependencies.

## Postscreen
Postscreen is configured to reduce load of spammers and bots on the mailserver, ip addresses can bypass postscreen by adding a relevant redis key to the redis container (a seperate redis container for rspamd is needed) eg to allow local lan traffic to bypass postscreen:
```redis-cli add PSA:192.168.0.0/24 permit```

To block an unwanted ip:
```redis-cli add PSA:8.8.8.8 reject```

To unblock an ip:
```redis-cli del PSA:8.8.8.8```

To list all redis keys:
```redis-cli keys \*```

## Mailserver Reverse DNS
If posfix receives an email from a mailserver that does not have a reverse dns entry it is rejected (even lan traffic), you can allow with the key:
```redis-cli set REV:192.168.0.8 permit```

## Helo hostname
Postfix checks for a valid Helo, an invalid response is rejected, to bypass this check or block a "Helo" use the prefix ```HLO```
```bash
redis-cli set HLO:REJECTEDMESSAGE permit
redis-cli set HLO:mail.spammer.bulk reject
```

## Virtual Mailboxes
These are configured with the following prefixes/keys:
```bash
virtual_mailbox_domains = redis:${config_directory}/redis-vdomains.cf   #VDOM
virtual_mailbox_maps = redis:${config_directory}/redis-vmailbox-maps.cf #VBOX
virtual_alias_maps = redis:${config_directory}/redis-valias-maps.cf     #VALI
```

The VDOM prefix is used for virtual domains to accept email for
```redis-cli set VDOM:example.com example.com```

The VBOX prefix/key is optional, see [here](http://www.postfix.org/postconf.5.html#virtual_mailbox_maps)

The VALI prefix is used to check a user exists, and setup aliases:
```bash
redis-cli set VALI:user1@example.com user1@example.com
redis-cli set VALI:user2@example.com user2@example.com
redis-cli set VALI:postmaster@example.com user1@example.com
redis-cli set VALI:sales@example.com "user1@example.com user2@example.com"
```

## Recipient access
Using the prefix ```RECIP``` recipient: resctrictions can be set up as described [here](http://www.postfix.org/RESTRICTION_CLASS_README.html)


## Redis Keys
The following redis keys are used

| KEY                          | Description                                                                         | Example                                                                             |
| ---------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| PSA:8.8.8.8                  | Bypass postscreen with 'permit' or reject at postscreen with 'reject'                             | redis-cli add PSA:192.168.0.0/24 permit<br>or to reject<br> redis-cli add PSA:8.8.8.8 reject                                          |
| REV:192.168.0.8              | Allow ip without a reverse DNS entry                      | redis-cli set REV:192.168.0.8 permit |
| HLO:REJECTEDMESSAGE          | Allow invalid "Helo" message eg from software sending email directly, or reject an unwanted one | redis-cli set HLO:REJECTEDMESSAGE permit |
| VDOM:example.com             | Virtual domain to accept email for | redis-cli set VDOM:example.com example.com |
| VALI:user@example.com        | Virtual mailbox alias key, used to check existence and create aliases | redis-cli set VALI:user@example.com user@example.com |
| VBOX:                        | Optional key for virtual mailbox maps | See [here](http://www.postfix.org/postconf.5.html#virtual_mailbox_maps) |
| RECIP:                       | Optional Recipent Acess Resctriction | See [here](http://www.postfix.org/RESTRICTION_CLASS_README.html) |

## SSL Certificates
The path for certificates to be mounted in is: ```/etc/letsencrypt```, the actual certificates should then be in the directory ```live/$LETSENCRYPT```.  This is usually mounted from a letsencrpyt/dnsrobocert container.

## Security
Postfix has its own rate limiting for failed emails, for extra security with firewalling use syslog-ng on the docker host and set the docker logging to journald so logs can be parsed by a service like fail2ban

## Github
Github Repository: [https://github.com/a16bitsysop/docker-postfix-redis](https://github.com/a16bitsysop/docker-postfix-redis)

## Environment Variables

| NAME        | Description                                                               | Default               |
| ----------- | ------------------------------------------------------------------------- | --------------------- |
| REDIS       | Name/container name or IP of the redis server                             | none                  |
| HOSTNAME    | FQDN Hostname for postfix to use (myhostname)                                               | none                  |
| LETSENCRYPT | Folder name for ssl certs (/etc/letsencrypt/live/$LETSENCRYPT/cert.pem)   | none                  |
| DOMAIN      | FQDN domain for myorigin                                                  | $myhostname  |
| RSPAMD      | Name/container name or IP of rspamd, for spam detection, dkim signing, etc                   | none                  |
| DOVECOT     | Name/container name or IP of dovecot, for email storage and auth                   | none                  |
| TIMEZONE    | Timezone to use inside the container, eg Europe/London                    | unset                 |

## Examples
To run connecting to container network exposing ports (accessible from host network), and docker managed volumes.  With ssl certificates mounted into /etc/letsencrypt
```bash
#docker container run -p 25:25 -p 587:587 --name postfix --restart=unless-stopped --mount source=postfix-var,target=/var/lib/postfix --mount source=ssl-certs,target=/etc/letsencrypt -d a16bitsysop/postfix-redis
```

### Sources
Based on configuration [here](https://thomas-leister.de/en/mailserver-debian-stretch/)
