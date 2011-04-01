# Makefile for Openhosting's tools collection

PROJS=\
	baseup \
	chroot_objects \
	check_errata \
	hotplug \
	pkgpurge \
	mailtail


SYSCONFDIR=/etc
DESTDIR?=
PREFIX?=/usr/local

BSD_INSTALL_DATA_DIR=install -d -o root -g bin -m 755
BSD_INSTALL_DATA=install -c -o root -g bin -m 444
BSD_INSTALL_SCRIPT=install -c -o root -g bin -m 555

.PHONY: ${PROJS}

install: generic_install_routine ${PROJS}

baseup:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${DESTDIR}${PREFIX}/sbin/
	${BSD_INSTALL_SCRIPT_DIR} ${DESTDIR}${PREFIX}/share/baseup
	${BSD_INSTALL_SCRIPT} $@/functions.sh ${DESTDIR}${PREFIX}/share/baseup/
	perl -pi -e "s,^(CONFIG=).*,\1${SYSCONFDIR}/baseup.conf," ${DESTDIR}${PREFIX}/sbin/$@
	perl -pi -e "s,^(FUNCS=).*,\1${LOCALBASE}/share/baseup/functions.sh," ${DESTDIR}${PREFIX}/sbin/$@
	perl -pi -e "s,^(TEMPS=).*,\1/var/tmp/$@," ${DESTDIR}${PREFIX}/sbin/$@

chroot_objects:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${DESTDIR}${PREFIX}/sbin/

check_errata:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${DESTDIR}${PREFIX}/bin/

hotplug:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT_DIR} ${DESTDIR}${PREFIX}/share/hotplug
	${BSD_INSTALL_SCRIPT} $@/hotplug_attach.sh ${DESTDIR}${PREFIX}/share/hotplug/attach.sh
	${BSD_INSTALL_DATA_DIR} ${DESTDIR}${PREFIX}/share/examples/hotplug
	${BSD_INSTALL_SCRIPT} $@/attach ${DESTDIR}${PREFIX}/share/examples/hotplug/
	${BSD_INSTALL_SCRIPT} $@/attach.conf ${DESTDIR}${PREFIX}/share/examples/hotplug/
	perl -pi -e "s,^(OHTOOLS_INST_PREFIX=).*,\1${LOCALBASE}," ${DESTDIR}${PREFIX}/share/examples/hotplug/attach

pkgpurge:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${DESTDIR}${PREFIX}/bin/

mailtail:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${DESTDIR}${PREFIX}/bin/

generic_install_routine:
.for p in ${PROJS}
	@echo "Installing documentation"
	${BSD_INSTALL_DATA_DIR} ${DESTDIR}${PREFIX}/share/doc/$p
	${BSD_INSTALL_DATA} LICENSE ${DESTDIR}${PREFIX}/share/doc/$p/
	-${BSD_INSTALL_DATA} $p/doc/* ${DESTDIR}${PREFIX}/share/doc/$p/
.endfor
