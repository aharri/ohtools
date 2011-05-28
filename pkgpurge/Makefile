all:

install:
	@echo "Installing ${SUBPROJ}"
	${INSTALL_SCRIPT} ${SUBPROJ} ${DESTDIR}${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${DESTDIR}${DATADIR}/${SUBPROJ}
	-${INSTALL_DATA} doc/* ${DESTDIR}${DATADIR}/${SUBPROJ}

.include "../Makefile.inc"

