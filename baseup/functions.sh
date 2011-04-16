#!/bin/sh
#
# $Id: functions.sh,v 1.15 2009/07/28 06:30:08 iku Exp $
#
# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>
#

function usage
{
	echo "Base upgrader."
	echo ""
	echo "Refer to file headers for appropriate copyright and legal notices"
	echo "or check the packaging for license files."
	exit 1
}

function query_index
{
	_VAL=$(cd "${TEMPS}" && egrep "(^|^.* )$1..\.tgz$" index.txt | perl -pe "s/(^|^.* )($1..\.tgz)$/\2/")
}

function check_sha256
{
	(cd "${TEMPS}" && fgrep "($1)" SHA256 | cksum -a sha256 -c) 1>/dev/null 2>&1
}

function check_filesize
{
	local size1=$(egrep "${1}$" "${TEMPS}/dirlisting.txt" | awk '{ print $5 }')
	local size2=$(ls -l "${TEMPS}/$1" 2>/dev/null | awk '{ print $5 }')

	if [ "$size1" = "$size2" ]; then
		return 0
	fi
	return 1
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
		# --nocomp   don't compare checksums
		# --nocheck  don't check for succesful download
		if [ "$file" = '--nocomp' ] || [ "$file" = '--nocheck' ]; then
			continue
		fi

		check_sha256 "$file"
		if [ "$?" -eq 0 ] && [ "$1" != '--nocomp' ]; then
			printf "%-12s %s\n" "$file" "CACHED (sha256 checked)"
			continue
		elif [ -e "${TEMPS}/$file" ] && [ "$1" != '--nocomp' ]; then
			check_filesize "$file"
			if [ "$?" -eq 0 ]; then
				printf "%-12s %s\n" "$file" "CACHED (size checked)"
				continue
			fi
		fi
		# XXX This might be nicer with user prompt
		rm -f "${TEMPS}/${file}"
		case $(echo "$source" | cut -f 1 -d ':') in 
			file )
				local src=$(echo "$source" | sed -e 's,^file://,,')
				cmd=$(cp "${src}/${file}" "${TEMPS}/${file}" 1>/dev/null 2>&1)
				code=$?
				if [ "$code" -eq 0 ]; then
					printf "%-12s %s\n" $file "GOOD"
				fi
			;;
			ftp|http )
				ftp -V -m -o "${TEMPS}/${file}" "${source}/${file}" 2>/dev/null
				code=$?
			;;
			* )
				echo "Unsupported URL scheme $src"
				exit 1
			;;
		esac
		if [ "$code" -ne 0 ]; then
			printf "%-12s %s\n" $file "FAILED with code $code"
			if [ "$1" != '--nocheck' ]; then
				exit 1
			fi
		fi
	done
}

function fetch_listing
{
	if [ -z "$1" ]; then
		echo "fetch listing: not enough parameters"
		exit
	fi
	case $(echo "$source" | cut -f 1 -d ':') in 
		file )
			local src=$(echo "$source" | sed -e 's,^file://,,')
			/bin/ls -l "$src" > "$1" 2>/dev/null
			code=$?	
		;;
		# http isn't tested
		ftp|http )
			which curl 1>/dev/null 2>/dev/null
			if [ "$?" -ne 0 ]; then
				echo "Curl not found, install it"
				exit 1
			fi

			#get_config source
			curl $CURL_OPTS "$source/" -o "$1"
			# FIXME: curl doesn't return !0 when failure
			code=$?
		;;
		* )
			echo "Unsupported URL scheme $src"
			exit 1
		;;
	esac
	if [ "$code" -eq 0 ]; then
		printf "%-12s %s\n" "dirlisting" "GOOD"
	else
		printf "%-12s %s\n" "dirlisting" "FAILED with code $code"
		# we need this file
		exit 1
	fi
	return 0
}

function init_source
{
	echo "What address shall I use as package source?"
	echo "Here's an example: http://ftp.eu.openbsd.org/pub/OpenBSD/snapshots/`uname -m`"
	echo "You can edit baseup.conf later if you get this wrong."
	read source
	set_config source "$source"
	if [ "$?" -ne "0" ]; then
		echo "Failed to set configuration."
		exit 1
	fi
}

# Yes/No function
# $1 is the message
# $2 is the default action, otherwise default is yes
yesno()
{
	local default
	# repeat if yes or no option not valid
	while true
	do
		# $* read first every parameter giving to the yesno function which will be the message
		echo -n "$1 "
		if [ -n "$2" ] && [ "$2" = "n" ]; then
			default=1
			echo -n "(y/N) "
		else
			default=0
			echo -n "(Y/n) "
		fi
		# junk holds the extra parameters yn holds the first parameters
		read yn junk
		# check for difference cases
		case $yn in
			yes|Yes|YES|y|Y)
				return 0
				;;
			no|No|n|N|NO)
				return 1
				;;
			"")
				return $default
				;;
		esac
	done    
}

