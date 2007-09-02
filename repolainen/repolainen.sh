#!/bin/sh

# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>

BASE=$(cd -- "$(dirname -- "$0")"; pwd)

# create temporary file
TMPFILE=$(mktemp)
if [ "$?" -ne 0 ]; then
	echo "Mktemp failed!"
	exit 1
fi

# pick up config
if [ ! -e "$BASE/config/repolainen.conf" ]; then
	echo "Edit configuration!"
	exit 1
fi
. "$BASE/config/repolainen.conf"

for REPO in $REPOSITORIES; do
	echo "Processing $REPO"
	eval SRC=$(echo "\$SRC_$REPO")
	eval DST=$(echo "\$DST_$REPO")
	eval FILTER=$(echo "\$FILTER_$REPO")
	echo "$FILTER" > "$TMPFILE"
	echo "$FILTER"
	echo $RSYNC $RSYNC_FLAGS --filter=". $TMPFILE" "$SRC" "$DST"
	$RSYNC $RSYNC_FLAGS --filter=". $TMPFILE" "$SRC" "$DST"
done

rm -f "$TMPFILE"
