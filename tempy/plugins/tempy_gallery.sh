#!/bin/sh
#
# $Id: tempy_gallery.sh,v 1.2 2007/11/10 04:29:30 iku Exp $
#
# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>
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

gallery()
{
	TMP=`mktemp` || exit 1

	echo '<div id="thumbnails">'

	IFS='
'
	local oldcat=
	local dirs=$(find "$GALLERY_ORIG" -mindepth 1 -maxdepth 2 -type d)
	local files=$(find $dirs -mindepth 1 -maxdepth 2 -iname '*.jpg' -or -iname '*.png' -or -iname '*.gif' | sort)
	local files2=$(find "$GALLERY_ORIG" -mindepth 1 -maxdepth 1 -iname '*.jpg' -or -iname '*.png' -or -iname '*.gif' | sort)
	for i in $files2 $files; do
		#echo $(dirname "$i" | sed -e "s,^${GALLERY_ORIG}/,,")
		local newcat=$(dirname "$i" | sed -e "s,^${GALLERY_ORIG}/,,")
		f="${GALLERY_THUMB}/"$(basename "$i")
		inode=$(ls -i "$i" | awk '{ print $1 }')
		line=$(grep "^${inode}[[:space:]]" ${GALLERY_DESC})
		if [ "$?" -ne 0 ]; then
			#echo "updating ${GALLERY_DESC}"
			echo "$inode \"&nbsp;\" $f" >> $TMP
			desc=''
		else
			desc=$(echo "$line" | cut -f 2 -d '"')
			echo "$line" >> $TMP
		fi
		if [ "$f" -ot "$i" ]; then
			#echo "$i is out of date"
			convert "$i" -resize ${GALLERY_DIMS} "$f"
		fi
		if [ "$oldcat" != "$newcat" ]; then
			oldcat=$newcat
			echo "<h2 style=\"clear: both;\">$newcat</h2>"
		fi
		echo "<div><a href=\"$i\"><img src=\"$f\" alt=\"$desc\" /></a><p>$desc</p></div>"
	done
	unset IFS
	echo "</div>"
	cp -f $TMP ${GALLERY_DESC} && rm -f $TMP
}
