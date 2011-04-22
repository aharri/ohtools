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
	echo "baseup [-hlrt]"
	echo ""
	echo " -h   print usage."
	echo " -l   list available snapshots."
	echo " -r   revert to previous snapshot."
	echo " -t   trim snapshots, delete all but one."
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
	PREVSNAP=$(get_snaps | head -n 1)
	if [ -z "${PREVSNAP}" ]; then
		PREVSNAP=$SNAPDIR
	elif [ "$PREVSNAP" = "$SNAPDIR" ]; then
		PREVSNAP=$(get_snaps | sed -n -e 2p)
	fi
	if [ ! -d "${TEMPS}/${SNAPDIR}" ]; then
		mktemp -d "${TEMPS}/${SNAPDIR}" 1>/dev/null 2>&1 || \
			errx "Could not create '${TEMPS}/${SNAPDIR}'"
	fi
}

# [--verbose] num
#
#  --verbose   enable verbose mode.
#  num         num number of snaps to leave.
#  
trim_snaps()
{
	local snap snaps param verbose=false num=1
	for param; do
		case "$param" in
		'--verbose') verbose=true;;
		[0-9]|[0-9][0-9]) num=$param;;
		esac	
	done
	snaps=$(get_snaps)

	if [ "$(printf "%s\n" "$snaps" | wc -l)" -le "$num" ]; then
		if $verbose; then
			echo "$num or less snapshots exists, not trimming."
		fi
		return 0
	fi
	echo "Trimming old snapshots.\n"

	cd "$TEMPS"

	count=0
	for snap in $snaps; do
		count=$((count + 1))
		if [ "$count" -le "$num" ]; then
			continue
		fi
		rm -rf "$snap"
		echo "Deleted old snapshot '$snap'"
	done
	echo ""
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

	echo "Listing previously fetched snapshots:"
	if [ -z "$snaps" ]; then
		printf "\nNone found.\n\n"
	else
		printf "\n%s\n\n" "$snaps" | fmt -w 1
	fi
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

# Output configuration setting on success.
# Otherwise return failure.
get_config()
{
	local value

	value=$(egrep "^$1=" "$CONFIG")
	if [ "$?" -ne 0 ] || [ -z "$value" ]; then
		return 1
	fi
	printf "%s\n" "$value" | cut -f 2 -d '=' | tail -n 1
}

set_config()
{
	# If configuration does not exist, create it
	touch "$CONFIG"
	if ! get_config "$1" 1>/dev/null; then
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

		if ! $nocomp; then
			check_sha256 "${TEMPS}/${SNAPDIR}" "$file" && \
				printf "%-12s %s\n" "$file" "CACHED (sha256 checked)" && \
				continue
			check_sha256 "${TEMPS}/${PREVSNAP}" "$file" && \
				printf "%-12s %s\n" "$file" "CACHED (sha256 checked)" && \
				(cd "${TEMPS}/${SNAPDIR}" && ln -f "../${PREVSNAP}/${file}") && \
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
			if ! $nocheck; then
				exit 1
			fi
		fi
	done
}

init_source()
{
	echo "What address shall I use as package source?"
	echo "Here's an example: http://ftp.eu.openbsd.org/pub/OpenBSD/snapshots/`uname -m`"
	echo "You can edit '${CONFIG}' later if you get this wrong."
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

install_kernel()
{
	cp -f /bsd /bsd.orig
	cp -f "${TEMPS}/${1}/"bsd* /

	set_config installing "$1"

	echo ""
	echo "Kernel(s) installed"
}

install_tgz()
{
	local param sysmerge='ask' sysmerge_cmd= dir

	dir=$(get_config installing)

	for param; do
		case "$param" in
		'--sysmerge=auto') sysmerge='auto';;
		'--sysmerge=ask') sysmerge='ask';;
		'--sysmerge=no') sysmerge='no';;
		*) dir=$param;;
		esac	
	done
	for pkg in "${TEMPS}/${dir}/"*.tgz; do
		case "$pkg" in
		*/etc[0-9][0-9].tgz)
			sysmerge_cmd="$sysmerge_cmd -s $pkg"
			echo "Skipping ${pkg}: merge with sysmerge!"
			continue
		;;
		*/xetc[0-9][0-9].tgz)
			sysmerge_cmd="$sysmerge_cmd -x $pkg"
			echo "Skipping ${pkg}: merge with sysmerge!"
			continue
		;;
		esac
		echo "Installing $pkg"
		(cd / && tar zxfp "$pkg") || break
	done

	set_config state install_kernel
	set_config installing ''

	echo ""	
	echo "Base installed."
	echo ""

	if [ -n "$sysmerge_cmd" ] && [ "$sysmerge" = "auto" ]; then
		sysmerge $sysmerge_cmd
	elif [ -n "$sysmerge_cmd" ] && [ "$sysmerge" = "ask" ]; then
		yesno "Run sysmerge (recommended)?" && sysmerge $sysmerge_cmd
	fi
}
