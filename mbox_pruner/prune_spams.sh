#!/bin/sh
#
# $Id: prune_spams.sh,v 1.3 2007/09/04 17:09:04 iku Exp $
#
# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>
#

BASE=$(cd -- "$(dirname -- "$0")"; pwd)
home=/home
getuids=${BASE}/getuids.sh
prune=${BASE}/prune.php
time=31

# check for installed script
if [ ! -x "$prune" ] || [ ! -x "$getuids" ]; then
	echo "getuids or prune missing or they have incorrect permissions"
	exit 1
fi

# check for readable home directory
if [ ! -d "$home" ]; then
	echo "$home is not usable"
	exit 1
fi

# main loop
directories=$($getuids | cut -f 6 -d ':')
for directory in $directories; do
	test=$(echo $directory | grep "^${home}/")
	if [ -z "$test" ]; then
		continue
	fi

	spambox="${directory}/mail/spam"

	if [ -f "$spambox" ] && [ ! -f  "${directory}/.no_spam_prune" ]; then
		echo -n "${directory}: "
		php -c "${BASE}/php.ini" "$prune" "$time" "$spambox"
	fi
done

spambox=~quarantine/mail/inbox
if [ -f "$spambox" ]; then
	echo -n "${spambox}: "
	php -c "${BASE}/php.ini" "$prune" "$time" "$spambox"
fi
