#!/bin/sh

## ABSOLUTE path to the spawn-fcgi binary
SPAWNFCGI="/usr/local/bin/spawn-fcgi"

## ABSOLUTE path to the PHP binary
FCGIPROGRAM=

## TCP port to which to bind on localhost
FCGIPORT="1026"
## Or socket, socket overrides FCGIPORT
PHP_FCGI_SOCKET=

## number of PHP children to spawn
PHP_FCGI_CHILDREN=10

## maximum number of requests a single PHP process can serve before it is restarted
PHP_FCGI_MAX_REQUESTS=1000

## IP addresses from which PHP should access server connections
FCGI_WEB_SERVER_ADDRS="127.0.0.1"

# allowed environment variables, separated by spaces
ALLOWED_ENV="PATH USER"

## if this script is run as root, switch to the following user
USERID=www
GROUPID=www

## chroot
WEBROOT=

## config directory containing php.ini
CONF_DIR=

################## no config below this line

if test x$PHP_FCGI_CHILDREN = x; then
  PHP_FCGI_CHILDREN=5
fi

export PHP_FCGI_MAX_REQUESTS
export FCGI_WEB_SERVER_ADDRS

ALLOWED_ENV="$ALLOWED_ENV PHP_FCGI_MAX_REQUESTS FCGI_WEB_SERVER_ADDRS"

if [ -n "$PHP_FCGI_SOCKET" ]; then
	BIND="-s $PHP_FCGI_SOCKET"
else
	BIND="-p $FCGIPORT"
fi

if [ -n "$1" ]; then
	PIDFILE="-P $1"
fi

if [ -n "$WEBROOT" ]; then
	WEBROOT="-c $WEBROOT"
fi

if [ x$(id -u) ]; then
	EX="$SPAWNFCGI $WEBROOT $PIDFILE $BIND -f $FCGIPROGRAM -u $USERID -g $GROUPID -C $PHP_FCGI_CHILDREN -- $FCGIPROGRAM -c $CONF_DIR"
else
	EX="$SPAWNFCGI $PIDFILE $BIND -f $FCGIPROGRAM -C $PHP_FCGI_CHILDREN -- $FCGIPROGRAM -c $CONF_DIR"
fi

# copy the allowed environment variables
E="LD_LIBRARY_PATH=/usr/X11R6/lib/"

for i in $ALLOWED_ENV; do
  eval val='$'$i
  E="$E $i=$val"
done

# clean the environment and set up a new one
env - $E $EX
