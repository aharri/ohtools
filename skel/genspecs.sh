#!/bin/sh

BASE=$(cd -- "$(dirname -- "$0")"; pwd)

cd "${BASE}/data"
mtree -c -k uid,gid,mode > "${BASE}/specs/fastcgi-vhost.spec"
