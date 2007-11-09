#!/bin/sh
#
# $Id: tempy_navi.sh,v 1.1 2007/11/09 20:19:17 iku Exp $
#
# Copyright (c) 2007 Lasse Collin <larhzu@tukaani.org>
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
	local THIS
	case $1 in
		index)    THIS=./ ;;
		*/index)  THIS=${1%/index}/ ;;
		*)        THIS=$1 ;;
	esac

	local URL NAME DESC
	# FIXME need "level" number for id=
	printf '\t\t<ul id="subnavi">\n' "$NAME"
	cat "$2" | while read -r URL NAME DESC ; do
		if [ "${URL%.html}" = "$THIS" ]; then
			printf '\t\t<li>%s</li>\n' "$NAME"
		else
			printf '\t\t<li><a href="%s" title="%s">%s</a></li>\n' \
					"$URL" "$DESC" "$NAME"
		fi
	done
	printf '\t\t</ul>\n' "$NAME"
}

navi()
{
	local DIR
	case $1 in
		*/*)	DIR=${1%/*} ;;
		*)      DIR=. ;;
	esac
	
	local URL NAME DESC
	IFS='	'
	printf '\t\t<ul id="navi">\n' "$NAME"
	cat _topnavi | while read -r URL NAME DESC ; do
		if [ "$DIR/" = "$URL" ]; then
			printf '\t<li>%s</li>\n' "$NAME"
			subnavi "$1" "$DIR/_subnavi"
		else
			printf '\t<li><a href="%s" title="%s">%s</a></li>\n' \
					"$URL" "$DESC" "$NAME"
		fi
	done
	printf '\t\t</ul>\n' "$NAME"
	unset IFS
}
