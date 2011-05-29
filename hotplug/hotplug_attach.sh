#!/bin/sh
#
# Copyright (c) 2006,2007,2011 Antti Harri <iku@openbsd.fi>
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
#
# KNOWN BUGS: This is not really a bug of this script,
# but `install` that comes with OpenBSD. If a directory
# 2007/09 will be installed recursively without either
# 2007 or 2007/09 existing before install command, then
# only 09/ will get permissions defined on the command
# line and 2007/ will get default permissions:
# iku@kameli:~/temp$ install -d -m 0700 2007/09
# iku@kameli:~/temp$ ls -ld 2007 2007/09
# drwxr-xr-x    3 iku      users         512 Sep 30 00:11 2007
# drwx------    2 iku      users         512 Sep 30 00:11 2007/09
#
# Configure your CAMMNT mount point in /etc/fstab, for example:
# 4f98a293132db4a0.i /mnt/digicam msdos rw,nodev,nosuid,noatime,noexec 0 0

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DEBUG()
{
	if [ -n "$DEBUG" ]; then
		logger "$1"
	fi
}
comparedevs()
{
	IFS=';'
	for DEV in $2; do
		echo "$1" | grep -q "$DEV"
		if [ "$?" -eq 0 ]; then
			unset IFS
			return 0
		fi
	done
	unset IFS
	return 1
}

DEVCLASS=$1
DEVNAME=$2
case $DEVCLASS in
0)
	# Use this with multiple USB printers in OpenBSD
	# that can allocate what ever usb-device is available.
	# It will create symlinks under /dev that point always
	# to the right /dev/devname.
	devicename=$(usbdevs -d | fgrep -B 1 "$DEVNAME" | head -n 1 | tr "[:upper:]" "[:lower:]" | cut -f 2 -d ':')

	comparedevs "$devicename" "$PRINTDEVS"
	if [ "$?" -ne 0 ]; then
		DEBUG "Could not match '${devicename}' against configured printers"
		DEBUG "Printers: $PRINTDEVS"
		exit 0
	fi

	shortdevicename=$(echo "$devicename" | tr -cd 'a-z0-9')
	file="/dev/$shortdevicename"
	if [ -h "$file" ]; then
		rm -f "$file"
	fi
	ln -s "/dev/${DEVNAME}" "$file"
	logger "$devicename connected, symlink updated"
;;
2)
	# This part should be -eu compatible.
	set -eu

	duid=$(disklabel "$DEVNAME" | sed -nE 's/^duid: (.*)$/\1/p')
	if [ -z "$duid" ] || [ "$duid" = "0000000000000000" ]; then
		DEBUG "No DUID set on '$DEVNAME'"
		exit 1
	fi
	if ! egrep -q "^${duid}\\..[[:space:]]+${CAMMNT}[[:space:]]" /etc/fstab; then
		DEBUG "DUID ($duid) did not match mount point '${CAMMNT}'"
	fi

	# Check for JPEG header tool
	if ! which jhead 1>/dev/null 2>/dev/null; then
		logger "JPEG header tool jhead not found."
		exit 1
	fi

	# Prepare user & group
	test -n "$CAMUSER" && CAMUSER="-o $CAMUSER"
	test -n "$CAMGROUP" && CAMGROUP="-g $CAMGROUP"

	# Prepare mount point
	if [ ! -d "$CAMMNT" ]; then
		mkdir -p "$CAMMNT"
	fi

	if ! mount "$CAMMNT"; then
		logger "Failed to mount '${CAMMNT}'."
		exit 1
	fi
	trap "umount \"$CAMMNT\"" 0 1 13 15

	TMP=$(mktemp -t -d hotplug.XXXXXXXXXX) || (logger "Could not create tmpdir"; exit 1)
	files=$(find "${CAMMNT}/" \( -iname '*.jpg' -or -iname '*.avi' \))
	if [ -z "$files" ]; then
		logger "No files on device."
		exit 0
	fi

	for file in $files; do
		install $CAMUSER $CAMGROUP -m "$CAMFILEMODE" "$file" "$TMP" 2>&1 || (logger "Failed to extract $file" ; continue)
		filename=$(basename "$file")
		if cmp -s "$file" "${TMP}/${filename}"; then
			rm -f "$file"
		else
			logger "Failed to extract file $filename"
		fi
	done
	# Transform file
	jhead -nf"$CAMFILEFORMAT" "${TMP}/"*.jpg 1>/dev/null

	year=$(date +%Y)
	month=$(date +%m)

	# Move jpegs
	for file in $(find "$TMP" -type f -iname '*.jpg'); do
		filename=$(basename "$file")
		exifyear=$(jhead "$file" | fgrep 'Date/Time' | cut -f 2 -d ':' | tr -d ' ')
		exifmonth=$(jhead "$file" | fgrep 'Date/Time' | cut -f 3 -d ':' | tr -d ' ')

		if [ -z "$exifyear" ]; then
			exifyear=$year
		fi
		if [ -z "$exifmonth" ]; then
			exifmonth=$month
		fi

		if ! install $CAMUSER $CAMGROUP -m "$CAMDIRMODE" -d \
			"${CAMDIR}/${exifyear}/" \
			"${CAMDIR}/${exifyear}/${exifmonth}/"
		then
			logger "Set up '${CAMDIR}/${exifyear}/${exifmonth}/'"
			continue
		fi
		if ! install $CAMUSER $CAMGROUP -m "$CAMFILEMODE" \
			"$file" \
			"${CAMDIR}/${exifyear}/${exifmonth}/"
		then
			logger "Failed to copy file $filename from TMP"
			continue
		fi
		rm -f "$file"
	done

	# Support for other than jpg follows
	for file in $(find "$TMP" -type f); do
		if ! install $CAMUSER $CAMGROUP -m "$CAMDIRMODE" -d \
			"${CAMDIR}/${year}/" \
			"${CAMDIR}/${year}/${month}/"
		then
			logger "Set up '${CAMDIR}/${exifyear}/${exifmonth}/'"
			continue
		fi
		if ! install $CAMUSER $CAMGROUP -m "$CAMFILEMODE" \
			"$file" \
			"${CAMDIR}/${year}/${month}/"
		then
			logger "Failed to copy file $filename from TMP"
			continue
		fi
		rm -f "$file"
	done
	rmdir "$TMP" || logger "Files remained in $TMP or unknown error"
;;
esac
