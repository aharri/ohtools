all:

install:
	@echo "Installing ${SUBPROJ}"
	test -d ${DESTDIR}${PREFIX}/bin/ || ${INSTALL_PROGRAM_DIR} ${DESTDIR}${PREFIX}/bin/
	${INSTALL_SCRIPT} ${SUBPROJ} ${DESTDIR}${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${DESTDIR}${DATADIR}/${SUBPROJ}
	${INSTALL_DATA} doc/* ${DESTDIR}${DATADIR}/${SUBPROJ}/

.include "../Makefile.inc"
