all:

install:
	@echo "Installing ${SUBPROJ}"
	test -d ${DESTDIR}${PREFIX}/sbin/ || ${INSTALL_PROGRAM_DIR} ${DESTDIR}${PREFIX}/sbin
	${INSTALL_SCRIPT} ${SUBPROJ} ${DESTDIR}${PREFIX}/sbin/
	${INSTALL_DATA_DIR} ${DESTDIR}${DATADIR}/${SUBPROJ}
	-${INSTALL_DATA} doc/* ${DESTDIR}${DATADIR}/${SUBPROJ}/

.include "../Makefile.inc"