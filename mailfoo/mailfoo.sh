#!/bin/sh

# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>

DEFAULT="${HOME}/mboxfoo"
SPAMBOX="${HOME}/mail/spamfoo"
LOGFILE="${HOME}/.mailfoolog"
QUARANTINE="quarantine@localhost"
NO_DELIV_GROUPS="sftponly nologin"

EX_NOUSER=67
EX_TEMPFAIL=75

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

# Get stdin
STDIN=$(cat)

# Save stdin into a file in case of a weird error happens
TMPFILE=$(mktemp) || exit 1
printf '%s\n' "$STDIN" > "$TMPFILE"

check_header ()
{
	printf '%s\n' "$STDIN" | sed '/^$/,$d' | egrep -q "$1" 
	return "$?"
}

# maildrop compatibility functions
_LOGFILE=
logfile () 
{
	_LOGFILE=$1
}

to ()
{
	postlock -l fcntl "$1" printf '%s\n' "$STDIN" >> "$1"
	if [ "$?" -eq 0 ]; then
		if [ -n "$_LOGFILE" ]; then
			loglines="FIXME"
			postlock -l fcntl "$_LOGFILE" printf '%s\n' "$loglines" >> "$_LOGFILE"
			# error checking here?
		fi
		# remove temp file and exit
		rm -f "$TMPFILE"
		exit 
	else
		echo -n ""
		# FIXME
	fi
}
xfilter ()
{
	STDIN=$(printf '%s\n' "$STDIN" | $@)
	return "$?"
}

# Check if user belongs to group that should not 
# be able to receive mail
for GRP in $NO_DELIV_GROUPS; do
	groups "$USER" | grep -q -w "$GRP"
	if [ "$?" -eq 0 ]; then
		exit "$EX_NOUSER"
	fi
done

# Prevents mail looping
check_header "^To: *$QUARANTINE\$"
if [ "$?" -eq 0 ]; then
	to "$DEFAULT"
fi

########### SPAM CHECKING ###########
# Run through spamassassin with spamc 
# Check if SpamAssassin assigned spam status to our mail
# (retval 1 = spam)
xfilter "spamc -E"
if [ "$?" -eq 1 ]; then
    to "$SPAMBOX"
fi

########### VIRUS CHECKING ###########
# 0 : No virus found.
# 1 : Virus(es) found.
# 2 : An error occured.
printf '%s\n' "$STDIN" | clamdscan --quiet --stdout -
case "$?" in
	0) xfilter "reformail -I 'X-Virus-Status: No'  -I 'X-Virus-Checker-Version: ClamAV'" ;;
	1) xfilter "reformail -I 'X-Virus-Status: Yes' -I 'X-Virus-Checker-Version: ClamAV'" ;;
	2) exit $EX_TEMPFAIL ;;
esac

########### DELIVER MAIL NORMALLY ###########
logfile $LOGFILE


if [ -x "$USER/.mailfoofilter" ]; then
	. "$USER/.mailfoofilter"
fi

to $DEFAULT
