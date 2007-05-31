#!/bin/sh

# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>
#
# All rights reserved.
#

function query_index
{
	_VAL=$(cd "${BASE}/tmp/" && grep "^$1..\.tgz" index.txt)
}
function check_md5
{
	(cd "${BASE}/tmp/" && fgrep "($1)" MD5 | md5 -c) 1>/dev/null 2>&1
}
function touch_file
{
	if [ ! -e "$1" ]; then
		touch "$1"
		if [ "$?" -ne 0 ]; then
			echo "Failed to create configuration file $1"
			exit 1
		fi
	fi
}
function get_config
{
	# If configuration does not exist, create it
	touch_file "$CONFIG"

	_VAL=$(egrep "^$1=" "$CONFIG")
	ret=$?
	if [ "$ret" -ne "0" ]; then
		return $ret
	fi
	_VAL=$(echo "$_VAL"	| cut -f 2 -d '=' | tail -n 1)
	
}
function set_config
{
	# If configuration does not exist, create it
	touch_file "$CONFIG"
	get_config $1
	if [ "$?" -ne "0" ]; then
		echo "$1=$2" >> "$CONFIG"
		return 0
	fi
	TMPFILE=`mktemp -t baseup.XXXXXXXXXX` || return 1
	sed "s,^$1=.*$,$1=$2," "$CONFIG" > "$TMPFILE"
	cp -f "$TMPFILE" "$CONFIG"
	rm -f "$TMPFILE"
	return 0
}

function fetch_files
{
	for file in $@; do
		# skip parameter
		if [ "$file" = '--verify' ]; then
			continue
		fi

		if [ "$1" = "--verify" ]; then
			check_md5 "$file"
			if [ "$?" -eq 0 ]; then
				printf "%-30s %s\n" $file "CACHED"
				continue;
			fi
		fi
		# XXX This might be nicer with user prompt
		rm -f "${BASE}/tmp/${file}"
		cmd=$(ftp -o "${BASE}/tmp/${file}" "${source}/${file}" 1>/dev/null 2>&1)
		code=$?
		if [ "$code" -eq 0 ]; then
			printf "%-30s %s\n" $file "GOOD"
		else 
			printf "%-30s %s\n" $file "FAILED with code $code"
		fi
	done
}

function init_source
{
	echo "Let's begin. What address shall I use as package source?"
	echo "Examples: "
	echo "ftp://ftp.se.openbsd.org/pub/OpenBSD/snapshots/i386"
	echo "ftp://ftp.openbsd.fi/pub/OpenBSD/4.0/i386"
	read source
	set_config source "$source"
	if [ "$?" -ne "0" ]; then
		echo "Failed to set configuration."
		exit 1
	fi
}
