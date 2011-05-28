all:

install:
	@echo "Installing ${SUBPROJ}"
	${INSTALL_DATA_DIR} ${DESTDIR}${DATADIR}/${SUBPROJ}
	test -d ${DESTDIR}${PREFIX}/sbin/ || ${INSTALL_PROGRAM_DIR} ${DESTDIR}${PREFIX}/sbin
	${INSTALL_DATA_DIR} ${DESTDIR}${EXAMPLES}/${SUBPROJ}
	${INSTALL_SCRIPT} ${SUBPROJ} ${DESTDIR}${PREFIX}/sbin/
	${INSTALL_SCRIPT} functions.sh ${DESTDIR}${DATADIR}/${SUBPROJ}/
	${INSTALL_SCRIPT} openbsd-install.sub ${DESTDIR}${DATADIR}/${SUBPROJ}/
	${INSTALL_DATA} .kconfig ${DESTDIR}${EXAMPLES}/${SUBPROJ}/baseup-kernel.conf
	-${INSTALL_DATA} doc/* ${DESTDIR}${DATADIR}/${SUBPROJ}/
	perl -pi -e "s,^(CONFIG=).*,\1${SYSCONFDIR}/baseup.conf," ${DESTDIR}${PREFIX}/sbin/${SUBPROJ}
	perl -pi -e "s,^(KCONFIG=).*,\1${SYSCONFDIR}/baseup-kernel.conf," ${DESTDIR}${PREFIX}/sbin/${SUBPROJ}
	perl -pi -e "s,^(INSTALL_SUB=).*,\1${LOCALBASE}/share/baseup/openbsd-install.sub," ${DESTDIR}${PREFIX}/sbin/${SUBPROJ}
	perl -pi -e "s,^(FUNCS=).*,\1${LOCALBASE}/share/baseup/functions.sh," ${DESTDIR}${PREFIX}/sbin/${SUBPROJ}
	perl -pi -e "s,^(TEMPS=).*,\1/var/tmp/${SUBPROJ}," ${DESTDIR}${PREFIX}/sbin/${SUBPROJ}

.include "../Makefile.inc"

