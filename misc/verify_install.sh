#!/bin/sh

# Copyright (c) 2008 Antti Harri <iku@openbsd.fi>
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

TMP1=$(mktemp) || exit 1
TMP2=$(mktemp) || exit 1

pkg_mklocatedb -nq | cut -f 2 -d ':' | sort -u > $TMP1
find /etc /usr/local | sort -u > $TMP2

echo "- marks a file that should exist but doesn't"
echo "+ marks a file that exists but doesn't exist in packages"
echo "press key to continue"
read

diff -u $TMP2 $TMP1 | less

rm -f $TMP1 $TMP2
