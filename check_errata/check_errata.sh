#!/bin/sh

# Very simple OpenBSD errata checker. Version 1.0.
# Run this once a day, for example:
# 01 05 * * * $HOME/bin/check_errata.sh [email] 

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

# servers
servers="openbsd.org www.openbsd.org openbsd.alpix.se openbsd.nuug.no"

# email
email=root@localhost

# use -u for unified diff
diff_opts="-u"

# where to store "cache"
file=$HOME/.openbsd_errata


# override email if specified on the command line
if [ -n "$1" ]; then
	email=$1
fi

# check for links
which links 1>/dev/null
if [ "$?" -eq 0 ]; then
	browser=links
else
	browser=lynx
fi

# create the cache directory/file if they doesn't exist
dir=$(cd -- "$(dirname -- "$0")"; pwd)
if [ ! -d "$dir" ]; then mkdir -p "$dir"; fi
if [ ! -e "$file" ]; then touch "$file"; fi

# create temporary file
TMPFILE=$(mktemp) || exit 1

# fetch new results
rev=$(uname -r | sed 's/\.//')
for host in $servers; do
	data=$("$browser" -dump "http://${host}/errata${rev}.html" 2>/dev/null)
	if [ "$?" -eq 0 ]; then break; fi
done
if [ -z "$data" ]; then
	exit 1
fi
print "$data" > "$TMPFILE"

# show the results
res=$(diff $diff_opts "$file" "$TMPFILE")
if [ -n "$res" ]; then
	echo "$res" | mail -s "OpenBSD Errata" "$email"
fi

# copy the file
cp -f "$TMPFILE" "$file"
rm -f "$TMPFILE"
