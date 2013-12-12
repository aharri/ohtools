#!/bin/bash
#
# Copyright (c) 2006,2007,2011,2013 Antti Harri <iku@openbsd.fi>
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

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DEBUG()
{
	if [ -n "$DEBUG" ]; then
		logger "$1"
	fi
}
usage()
{
	echo "$0 [-r] DIRS"
	echo "$0 -d"
	echo ""
	echo "[-r]      Doesn't delete source media"
	echo "DIRS      DIRS is one or more paths to extract from the source media"
	echo ""
	echo "-d        Print debug information under /root/hotplug-debug"
	echo ""
	echo "If the following variables don't exist then DIRS is extracted without"
	echo "trying to mount anything: DEVNAME && SUBSYSTEM=block || GPHOTO2_DRIVER=PTP"
	exit 1
}

cleanup()
{
	_cleanup="$@; $_cleanup"
}
_cleanup()
{
	eval "$_cleanup"
}

process_pics()
{
	set -eu
	IMGDIR=$1

	trap "_cleanup" RETURN EXIT HUP PIPE TERM #0 1 13 15

	CAMMNT=$(TMPDIR=/mnt mktemp -t -d hotplug.mountpoint.XXXXXXXXXX) || (logger "Could not create tmpdir"; exit 1)
	cleanup "rmdir \"$CAMMNT\""

	# USB Mass Storage specific block.
	if [ -n "$DEVNAME" ] && [ "$SUBSYSTEM" = "block" ]; then
		# Example:
		# DEVLINKS=/dev/disk/by-id/usb-Nokia_Nokia_6303i_clas_352682043498061-0:0-part1 \
		# /dev/disk/by-path/pci-0000:00:1d.3-usb-0:2:1.0-scsi-0:0:0:0-part1 \
		# /dev/disk/by-uuid/0007-1C8D

		TMP=$(mktemp -t -d hotplug.XXXXXXXXXX) || (logger "Could not create tmpdir"; exit 1)
		cleanup "rmdir \"$TMP\""

		if ! mount $WRITEFLAG "$DEVNAME" "$CAMMNT"; then
			WRITEFLAG="-o ro"
			# Default is R/W mount and it failed, try again R/O. If
			# The user wanted R/O originally, then we'll just try again.
			if ! mount $WRITEFLAG "$DEVNAME" "$CAMMNT"; then
				logger "Failed to mount '${CAMMNT}'."
				exit 1
			fi
		fi
		cleanup "umount \"$CAMMNT\""

		files=$(find "${CAMMNT}/${IMGDIR}" \( -iname '*.jpg' -or -iname '*.jpeg' -or -iname '*.avi' -or -iname '*.mts' \) || :)
		if [ -z "$files" ]; then
			logger "No files on device."
			return 0
		fi
		unset files

		for file in "${CAMMNT}/${IMGDIR}"/**/*.{jpg,jpeg,avi,cpi,mts}; do
			install -p $CAMUSER $CAMGROUP -m "$CAMFILEMODE" "$file" "$TMP" 2>&1 || (logger "Failed to extract $file" ; continue)
			filename=${file##*/}
			if [ "x$WRITEFLAG" = "x-rw" ]; then
				if cmp -s "$file" "${TMP}/${filename}"; then
					rm -f "$file"
				else
					logger "Failed to extract file $filename"
				fi
			fi
		done
	# USB PTP specific block.
	elif [ "$GPHOTO2_DRIVER" = "PTP" ]; then
		TMP=$(mktemp -t -d hotplug.XXXXXXXXXX) || (logger "Could not create tmpdir"; exit 1)
		cleanup "rmdir \"$TMP\""

		port=$(gphoto2 --auto-detect | grep "^$CAMID" | sed -Ee "s#.* (usb:.*)#\1#")
		cd "${TMP}"
		gphoto2 --port "$port" --quiet -P
		test "x$WRITEFLAG" = "x-rw" && gphoto2 --port "$port" --quiet -DR
	else
		# It seems that user just wants to extract the directories
		NOMOUNT=yes
		TMP=$1
	fi

	# Move files, don't loop .cpi here
	for srcfile in "$TMP"/*.{jpg,jpeg,avi,mts}; do
		suffix=${srcfile##*.} # Get the suffix
		suffix=${suffix,,} # Lower case it
		case "$suffix" in
			jpg|jpeg|avi|mts)
				exifdatestr=
				for string in DateTimeOriginal ModifyDate; do
					logger "Using $string to get snapshot date/time"
					exifdatestr=$(exiftool -d "%Y-%m-%dT%H:%M:%S" -"$string" "$srcfile" | cut --complement -f -1 -d ':')
					if [ -n "$exifdatestr" ]; then
						break
					fi
				done
				if [ -z "$exifdatestr" ]; then
					logger "Falling back to timestamp of the file instead of EXIF headers"
					exifdatestr=$(date --date="@$(stat -c %Z "$srcfile")" +"%Y-%m-%dT%H:%M:%S")
					logger "Failed to get date"
				fi
				formatted_filename=$(date --date="$exifdatestr" +"$CAMFILEFORMAT")
				exifyear=$(date --date="$exifdatestr" +"%Y")
				exifmonth=$(date --date="$exifdatestr" +"%m")
			;;	
		esac

		if ! install -p $CAMUSER $CAMGROUP -m "$CAMDIRMODE" -d \
			"${CAMDIR}/${exifyear}/" \
			"${CAMDIR}/${exifyear}/${exifmonth}/"
		then
			logger "Set up '${CAMDIR}/${exifyear}/${exifmonth}/'"
			continue
		fi
		if ! install -p $CAMUSER $CAMGROUP -m "$CAMFILEMODE" \
			"$srcfile" \
			"${CAMDIR}/${exifyear}/${exifmonth}/${formatted_filename}.${suffix}"
		then
			logger "Failed to copy file $srcfile"
			continue
		fi
		# Copy also the .CPI file
		case "$suffix" in
			mts)
				srcdir=${srcfile%/*}
				filename=${srcfile##*/}
				filename=${filename%.*} # Without suffix
				find "$srcdir/" -type f -iname "${filename}.cpi" -print0 | xargs -0r -IFILE \
					install -p $CAMUSER $CAMGROUP -m "$CAMFILEMODE" \
					FILE \
					"${CAMDIR}/${exifyear}/${exifmonth}/${formatted_filename}.cpi"
				find "$srcdir/" -type f -iname "${filename}.cpi" -print0 | xargs -0r rm -f
			;;
		esac
		if [ -n "$NOMOUNT" ] && [ "x$WRITEFLAG" = "x-rw" ] || [ -z "$NOMOUNT" ]; then
			rm -f "$srcfile"
		fi
	done

}
. "$_ATTACH_CONF"
if [ -n "$DEBUG" ]; then
	mkdir -p /root/hotplug-debug || exit 1
	test -z "$ID_MODEL" && ID_MODEL=interactive_session
	test -z "$USEC_INITIALIZED" && USEC_INITIALIZED=$(date +%s)
	exec > "/root/hotplug-debug/${ID_MODEL}.${USEC_INITIALIZED}.txt" 2>&1
	set -x
	env
fi

#test "$ACTION" != "add" && exit 0

test -z "$DEVNAME" && DEVNAME=
test -z "$IMGDIR" && IMGDIR=
test -z "$GPHOTO2_DRIVER" && GPHOTO2_DRIVER=

set -eu

# failglob:	do not run the loop at all if there are no files
# nocaseglob:	case-insensitive glob for loops
# globstar:	** in for-statement will do recursive loops
# nullglob:	* does not enter loop for string "*" if there
#		are no files
shopt -s nocaseglob globstar nullglob

# Prepare user & group.
test -n "$CAMUSER" && CAMUSER="-o $CAMUSER"
test -n "$CAMGROUP" && CAMGROUP="-g $CAMGROUP"

NOMOUNT=
WRITEFLAG=-rw

while getopts ":dr" opt; do
	case $opt in
		d) env ; exit 0 ;;
		r) WRITEFLAG="-o ro" ;;
		\?) echo "Invalid option: -$OPTARG" >&2; usage ;;
	esac
done
for param; do
	case "$param" in
		-*) ;;
		*)
			_cleanup=":"
			process_pics "$param"
			trap - RETURN EXIT HUP PIPE TERM
		;;
	esac
done
