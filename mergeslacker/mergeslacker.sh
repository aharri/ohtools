#!/bin/sh
#
# $Id: mergeslacker.sh,v 1.7 2007/10/01 20:41:31 iku Exp $
#
# Copyright (c) 2006,2007 Antti Harri <iku@openbsd.fi>
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

TMPFILE=
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

filelist=$(find /etc /var /usr -name "*.new" -type f 2>/dev/null)

for file in $filelist; do
	origfile=$(echo $file | sed 's/\.new$//')
	basename=$(basename "$origfile")

	# Original doesn't exist.
	if [ ! -e "$origfile" ]; then
		echo "no such file $basename, moving $file"
		# Do mv instead of cp+rm to keep permissions
		# set by packager.
		mv "$file" "$origfile"
		continue
	fi
	
	# Original exists, diff both.
	cmp=$(cmp -s "$origfile" "$file")
	cmp=$?

	# No difference -> delete .new .
	if [ "$cmp" -eq 0 ]; then
		echo "deleting $file"
		rm -f "$file"
		continue

	# User has modified files or the newly shipped file
	# differs otherwise with the old.
	else
		while [ 0 ]; do
			if [ -n "$TMPFILE" ]; then
				echo "Diff'ed file exists ($file)"
				echo ""
				echo "[D]elete the temporary file and go back to the previous menu"
				echo "[I]nstall the newly created file"
				echo "[v]iew the contents"
				read ans
				case "$ans" in
					"D")
						echo "deleting temporary file"
						rm -f "$TMPFILE"
						TMPFILE=
						continue
					;;
					"I")
						echo "installing new file"
						cp "$TMPFILE" "$origfile"
						rm -f "$TMPFILE" "$file"
						TMPFILE=
						break
					;;
					"v")
						more "$TMPFILE"
						continue
					;;
				esac
			fi
			echo "File differs: $file"
			echo ""
			echo "[d]iff files"
			echo "[D]elete .new"
			echo "[i]nteractively merge files together"
			echo "[I]nstall .new"
			echo -n "[l]eave as is for further use (default) "
			read ans
			case "$ans" in 
				"d")
					diff -a -u "$origfile" "$file" | more
					continue
				;;
				"D")
					echo "deleting $file"
					rm -f "$file"
					break
				;;
				"i")
					TMPFILE=$(mktemp -q /tmp/mergeslacker.XXXXXXXXXX)
					if [ "$?" -ne 0 ]; then
						echo "error creating temporary file, trying to continue"
						continue
					fi
					sdiff -o "$TMPFILE" "$origfile" "$file"
					continue

				;;
				"I")
					echo "moving $file to $basename"
					cp "$file" "$origfile"
					rm -f "$file"
					break
				;;
				*)
					break
				;;
			esac
		done
	fi
done
