DBFILE=zoner-dns.db
CONFIG=zoner-config.php
COOKIE=zoner-cookiefile

all: ca/ca-bundle.crt ${DBFILE} ${COOKIE} ${CONFIG}

ca/ca-bundle.crt:
	cd ca/ && perl mk-ca-bundle.pl

${DBFILE}:
	echo 'create table dyndns \
	(id integer primary key, \
	user text, \
	pass text, \
	fqdn text \
	oldip text, \
	newip text);' | sqlite3 ${DBFILE}

${COOKIE}:
	touch ${COOKIE} && chmod 600 ${COOKIE}

${CONFIG}:
	install -m 600 ${CONFIG}.sample ${CONFIG}
	@echo "Remember to edit ${CONFIG}"
