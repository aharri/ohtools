#!/bin/sh

BASE=$(cd -- "$(dirname -- "$0")"; pwd)

files="	check_errata/check_errata.sh
		baseup/baseup
		mergeslacker/mergeslacker.sh"

cd "$BASE/bin"
for file in $files; do
	ln -s ../$file
done
