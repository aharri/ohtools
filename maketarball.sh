#!/bin/sh

set -e

BASE=$(cd -- "$(dirname -- "$0")"; pwd)

if [ -z "$1" ]; then
	TAG=HEAD
	REL=current
else
	TAG=$1
	REL=$1
fi

cd /tmp
cvs -dopenbsd.fi:/var/cvs -q export -r"$TAG" ohtools
find ohtools -name .cvsignore -type f -print0 | xargs -0r rm -f
mv ohtools ohtools-"$REL"
tar zcf "$BASE"/ohtools-"$REL".tar.gz ohtools-"$REL"
rm -rf ohtools-"$REL"
