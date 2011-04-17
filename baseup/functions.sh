#!/bin/sh
#
# Copyright (c) 2007,2011 Antti Harri <iku@openbsd.fi>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

usage()
{
	echo "Interactive OpenBSD base system upgrade tool."
	echo ""
	echo "baseup [-hlpr]"
	echo ""
	echo " -h   print usage."
	echo " -l   list available snapshots."
	echo " -p   purge previous snapshot(s)."
	echo " -r   revert to previous snapshot."
	echo ""
	exit 1
}

# Print given error and exit.
errx()
{
	mesg="Error, exiting."
	if [ -n "$1" ]; then
		mesg=$1
	fi
	printf "%s\n" "$mesg"
	exit 1
}

# Set up temporary directories.
setup_tempdirs()
{
	local snaps
	# XXX: race condition
	if [ ! -d "$TEMPS" ]; then
	    mktemp -d "$TEMPS" 1>/dev/null 2>&1 || errx "Could not create '${TEMPS}'."
	fi
	SNAPDIR=$(date "+%Y-%m-%d-%H")
	snaps=$(get_snaps)
	PREVSNAP=$(printf "%s\n" "$snaps" | head -n 1)
	if [ -z "${PREVSNAP}" ]; then
		PREVSNAP=$SNAPDIR
	fi
	if [ ! -d "${TEMPS}/${SNAPDIR}" ]; then
		mktemp -d "${TEMPS}/${SNAPDIR}" 1>/dev/null 2>&1 || \
			errx "Could not create '${TEMPS}/${SNAPDIR}'"
	fi
}

get_snaps()
{
	local snaps
	local snaps2; snaps2=

	cd "$TEMPS"
	snaps=$(find . -name "????-??-??-??" -type d | cut -f 2 -d '/' | sort -n)

	for i in $snaps; do
		[ -f "${i}"/SHA256 ] && \
		[ -f "${i}"/index.txt ] && \
		snaps2="$i $snaps2"
	done
	printf "%s\n" "$snaps2" | fmt -w 1
}
# List snapshots.
list_snaps()
{
	local snaps

	snaps=$(get_snaps)

	if [ -z "$snaps" ]; then
		snaps="None found."
	fi
	echo "Listing previously fetched snapshots:"
	printf "\n%s\n\n" "$snaps" | fmt -w 1
}

query_index()
{
	_VAL=$(cd "${TEMPS}/${SNAPDIR}" && egrep "(^|^.* )$1..\.tgz$" index.txt | perl -pe "s/(^|^.* )($1..\.tgz)$/\2/")
}

# $1 = directory with SHA256
# $2 = what package to checksum
check_sha256()
{
	(cd "$1" && fgrep "($2)" SHA256 | cksum -a sha256 -c) 1>/dev/null 2>&1
}

get_config()
{
	# If configuration does not exist, create it
	touch "$CONFIG"

	_VAL=$(egrep "^$1=" "$CONFIG")
	ret=$?
	if [ "$ret" -ne "0" ]; then
		return $ret
	fi
	_VAL=$(echo "$_VAL"	| cut -f 2 -d '=' | tail -n 1)
	
}

set_config()
{
	# If configuration does not exist, create it
	touch "$CONFIG"
	if ! get_config "$1"; then
		echo "$1=$2" >> "$CONFIG"
		return 0
	fi
	TMPFILE=`mktemp -t baseup.XXXXXXXXXX` || return 1
	sed "s,^$1=.*$,$1=$2," "$CONFIG" > "$TMPFILE"
	cp -f "$TMPFILE" "$CONFIG"
	rm -f "$TMPFILE"
	return 0
}

fetch_files()
{
	local nocomp;  nocomp=false
	local nocheck; nocheck=false
	for file in $@; do
		case "$file" in
			'--nocomp')  nocomp=true;  continue;;
			'--nocheck') nocheck=true; continue;;
		esac

		if [ "$nocomp" = false ]; then
			check_sha256 "${TEMPS}/${SNAPDIR}" "$file" && \
				printf "%-12s %s\n" "$file" "CACHED (sha256 checked)" && \
				continue
			check_sha256 "${TEMPS}/${PREVSNAP}" "$file" && \
				printf "%-12s %s\n" "$file" "CACHED (sha256 checked)" && \
				(cd "${TEMPS}/${SNAPDIR}" && ln -s "../${PREVSNAP}/${file}") && \
				continue
		fi

		# XXX This might be nicer with user prompt
		rm -f "${TEMPS}/${SNAPDIR}/${file}"
		case $(echo "$source" | cut -f 1 -d ':') in 
			file )
				local src=$(echo "$source" | sed -e 's,^file://,,')
				cmd=$(cp "${src}/${file}" "${TEMPS}/${SNAPDIR}/${file}" 1>/dev/null 2>&1)
				code=$?
				if [ "$code" -eq 0 ]; then
					printf "%-12s %s\n" $file "GOOD"
				fi
			;;
			ftp|http )
				ftp -V -m -o "${TEMPS}/${SNAPDIR}/${file}" "${source}/${file}" 2>/dev/null || :
				code=$?
			;;
			* )
				errx "Unsupported URL scheme $src"
			;;
		esac
		if [ "$code" -ne 0 ]; then
			printf "%-12s %s\n" $file "FAILED with code $code"
			if [ "$nocheck" = false ]; then
				exit 1
			fi
		fi
	done
}

init_source()
{
	echo "What address shall I use as package source?"
	echo "Here's an example: http://ftp.eu.openbsd.org/pub/OpenBSD/snapshots/`uname -m`"
	echo "You can edit baseup.conf later if you get this wrong."
	read source
	set_config source "$source"
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
		if [ -n "${2:-}" ] && [ "${2:-}" = "n" ]; then
			default=1
			echo -n "(y/N) "
		else
			default=0
			echo -n "(Y/n) "
		fi
		# junk holds the extra parameters yn holds the first parameters
		read yn junk
		# Convert to lowercase for comparison.
		yn=$(printf "%s\n" "$yn" | tr "[:upper:]" "[:lower:]")
		# check for difference cases
		case $yn in
			yes|y)
				return 0
				;;
			no|n)
				return 1
				;;
			"")
				return $default
				;;
		esac
	done    
}

