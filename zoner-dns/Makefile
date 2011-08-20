DBFILE=zoner-dns.db
CONFIG=zoner-config.php
COOKIE=zoner-cookiefile

all: ca/ca-bundle.crt ${DBFILE} ${COOKIE} ${CONFIG}

ca/ca-bundle.crt:
	cd ca/ && perl mk-ca-bundle.pl

${DBFILE}:
	php usermod.php init

${COOKIE}:
	touch ${COOKIE} && chmod 600 ${COOKIE}

${CONFIG}:
	install -m 600 ${CONFIG}.sample ${CONFIG}
	@echo "Remember to edit ${CONFIG}"
