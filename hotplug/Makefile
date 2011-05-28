all:

install:
	@echo "Installing ${SUBPROJ}"
	${INSTALL_DATA_DIR} ${DESTDIR}${EXAMPLES}/${SUBPROJ}/
	${INSTALL_DATA_DIR} ${DESTDIR}${DATADIR}/${SUBPROJ}
	${INSTALL_SCRIPT} hotplug_attach.sh ${DESTDIR}${DATADIR}/${SUBPROJ}/attach.sh
	${INSTALL_SCRIPT} attach ${DESTDIR}${EXAMPLES}/${SUBPROJ}/
	${INSTALL_SCRIPT} attach.conf ${DESTDIR}${EXAMPLES}/${SUBPROJ}/
	${INSTALL_DATA} doc/* ${DESTDIR}${DATADIR}/${SUBPROJ}/
	perl -pi -e "s,^(OHTOOLS_INST_PREFIX=).*,\1${LOCALBASE}," ${DESTDIR}${EXAMPLES}/${SUBPROJ}/attach

.include "../Makefile.inc"

