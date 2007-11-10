#!/bin/sh
#
# $Id: tempy_navi.sh,v 1.3 2007/11/10 16:54:50 iku Exp $
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

subnavi()
{
	local subdir; subdir=''
#	case $1 in
#		index)    THIS=./ ;;
#		*/index)  THIS=${1%/index}/ ;;
#		*)        THIS=$1 ;;
#	esac

	local URL NAME DESC
	# FIXME need "level" number for id=
	printf '\t\t<ul id="subnavi">\n'
	IFS='	'
	printf "$TPLS" | while read -r URL NAME DESC ; do
		# XXX: currently supports only one sub level
		case $URL in
			*/)       subdir=$URL   ; continue ;;
			..)       subdir=''     ; continue ;;
		esac

		# Found the right subdir.
		if [ "$subdir" = "$2" ]; then
#			printf '\t\t<li>%s</li>\n' "$NAME"
			printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
				"${subdir}${URL}.html" "$DESC" "$NAME"
		fi
#		if [ "${URL%.html}" = "$THIS" ]; then
#			printf '\t\t<li>%s</li>\n' "$NAME"
#		else
#			printf '\t\t<li><a href="%s" title="%s">%s</a></li>\n' \
#					"$URL" "$DESC" "$NAME"
#		fi
	done
	printf '\t\t</ul>\n'
}

navi()
{
	local subdir DIR
	local TMPFILE
	local URL NAME DESC

#	case $1 in
#		*/*)	DIR=${1%/*} ;;
#		*)      DIR=. ;;
#	esac
	DIR=$(dirname "$1")/

	TMPFILE=$(mktemp) || exit 1

	IFS='	'
	printf '<ul id="navi">\n'
	printf "$TPLS" | while read -r URL NAME DESC; do
		# XXX: currently supports only one sub level
		case $URL in
			*/)
				subdir=$URL
				if [ "$DIR" = "$subdir" ]; then
					printf '\t<li>%s</li>\n' "$DESC"
					if [ "$NAVI_STYLE" = "vert" ]; then
						printf '\t<li>\n'
						subnavi "$1" "$subdir"
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
			..)       subdir=''     ; continue ;;
		esac
		if [ -n "$subdir" ]; then
			continue
		fi
#		else
		printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
			"${subdir}${URL}.html" "$DESC" "$NAME"
#		fi
#		if [ "$DIR/" = "$URL" ]; then
#			printf '\t<li>%s</li>\n' "$NAME"
#			subnavi "$1" "$DIR/_subnavi"
#		else
#			printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
#					"${URL}.html" "$DESC" "$NAME"
#		fi
	done
	printf '</ul>\n'
	unset IFS

	subdir=$(cat "$TMPFILE")
	if [ -n "$subdir" ] && [ "$NAVI_STYLE" = "horiz" ]; then
#		printf '<ul>\n\t<li>\n'
#		echo "$1 $subdir"
		subnavi "$1" "$subdir"
#		printf '\t</li>\n</ul>'
	fi
	rm -f "$TMPFILE"

}
