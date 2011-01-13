DBFILE=zoner-dns.db
CONFIG=zoner-config.php
COOKIE=zoner-cookiefile

all: ca/ca-bundle.crt ${DBFILE} ${COOKIE} ${CONFIG}
.PHONY: ${DBFILE}

ca/ca-bundle.crt:
	cd ca/ && perl mk-ca-bundle.pl

${DBFILE}: ${DBFILE}.sample
	test -f ${DBFILE} || install -m 600 ${DBFILE}.sample ${DBFILE}

${COOKIE}:
	touch ${COOKIE} && chmod 600 ${COOKIE}

${CONFIG}:
	install -m 600 ${CONFIG}.sample ${CONFIG}
	@echo "Remember to edit zoner.config.php"
