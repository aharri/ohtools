#!/bin/sh
# 
# $Id: getuids.sh,v 1.3 2007/09/04 17:09:04 iku Exp $
#
# Copyright (c) 2007 Antti Harri <iku@openbsd.fi>
#

# [min,max[
min=1000
max=2000

OLD_IFS=$IFS

# newline
IFS="
"

if [ -n "$1" ]; then
	min=$1
fi

if [ -n "$2" ]; then
	max=$2
fi

for line in $(cat /etc/passwd); do
	uid=$(echo "$line" | cut -f 3 -d ':')
	if [ "$uid" -ge $min ] && [ "$uid" -lt $max ]; then
		user=$(echo "$line" | cut -f 1 -d ':')
		echo "$line"
	fi
done
