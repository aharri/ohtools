#!/bin/sh
#
# $Id: tempy_navi.sh,v 1.7 2007/11/24 18:06:04 iku Exp $
#
# Original author:
# Copyright (c) 2007 Lasse Collin <larhzu@tukaani.org>
#
# Modified by:
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

# XXX: currently supports only one sub level

subnavi()
{
	local sublevel
	local subdir; subdir=''
	local URL NAME DESC

	if [ -n "$3" ] && [ "$3" -gt 1 ]; then
		sublevel=$3
	fi

	printf '<ul id="subnavi%s">\n' "$sublevel"
	IFS='	'
	printf '%s' "$TPLS" | while read -r URL NAME DESC ; do
		case $URL in
			*/)       subdir=$URL   ; continue ;;
			..)       subdir=''     ; continue ;;
		esac

		# Found the right subdir.
		if [ "$subdir" = "$2" ]; then
			printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
				"${subdir}${URL}.html" "$DESC" "$NAME"
		fi
	done
	printf '</ul>\n'
}

navi()
{
	local subdir DIR
	local TMPFILE
	local URL NAME DESC
	local sublevel; sublevel=-1

	DIR=$(dirname "$1")/

	TMPFILE=$(mktemp) || exit 1

	IFS='	'
	printf '<ul id="navi">\n'
	printf '%s' "$TPLS" | while read -r URL NAME DESC; do
		case $URL in
			*/)
				sublevel=$((sublevel + 1))
				subdir=$URL
				if [ "$DIR" = "$subdir" ]; then
					printf '\t<li><span>%s</span></li>\n' "$NAME"
					if [ "$NAVI_STYLE" = "vert" ]; then
						printf '\t<li>\n'
						subnavi "$1" "$subdir" "$sublevel"
						printf '\t</li>\n'
					else
						printf '%s\n' "$subdir" >> "$TMPFILE"
					fi
				else
					printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
						"${URL}" "$DESC" "$NAME"
				fi
				continue
			;;
			..)
				sublevel=$((sublevel - 1))
				subdir=''
				continue
			;;
		esac
		if [ -n "$subdir" ]; then
			continue
		fi
		printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
			"${subdir}${URL}.html" "$DESC" "$NAME"
	done
	printf '</ul>\n'
	unset IFS

	subdir=$(cat "$TMPFILE")
	if [ -n "$subdir" ] && [ "$NAVI_STYLE" = "horiz" ]; then
		subnavi "$1" "$subdir" "1"
	fi
	rm -f "$TMPFILE"

}
