# Makefile for Openhosting's tools collection

PROJS=\
	baseup \
	chroot_objects \
	tempy \
	check_errata \
	hotplug \
#	mbox_pruner


SYSCONFDIR=/etc
PREFIX?=/usr/local

BSD_INSTALL_DATA_DIR=install -d -o root -g bin -m 755
BSD_INSTALL_DATA=install -c -o root -g bin -m 444
BSD_INSTALL_SCRIPT=install -c -o root -g bin -m 555

.PHONY: ${PROJS}

install: generic_install_routine ${PROJS}

baseup:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/functions.sh ${PREFIX}/libexec/baseup_functions.sh
	perl -pi -e "s,^(CONFIG=).*,\1${SYSCONFDIR}/baseup.conf," ${PREFIX}/sbin/$@
	perl -pi -e "s,^(FUNCS=).*,\1${PREFIX}/libexec/baseup_functions.sh," ${PREFIX}/sbin/$@
	perl -pi -e "s,^(TEMPS=).*,\1/var/tmp/$@/," ${PREFIX}/sbin/$@
	${BSD_INSTALL_SCRIPT} $@/$@ ${PREFIX}/sbin/

chroot_objects:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${PREFIX}/sbin/

tempy:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/plugins/tempy_*.sh ${PREFIX}/libexec/
	${BSD_INSTALL_SCRIPT} $@/$@ ${PREFIX}/bin/

check_errata:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/$@ ${PREFIX}/bin/

hotplug:
	@echo "Installing project specific files for $@"
	${BSD_INSTALL_SCRIPT} $@/hotplug_attach.sh ${PREFIX}/libexec/
	${BSD_INSTALL_DATA_DIR} ${PREFIX}/share/examples/hotplug
	${BSD_INSTALL_SCRIPT} $@/attach ${PREFIX}/share/examples/hotplug/
	${BSD_INSTALL_SCRIPT} $@/attach.conf ${PREFIX}/share/examples/hotplug/
	perl -pi -e "s,^(OHTOOLS_INST_PREFIX=).*,\1${LOCALBASE}," ${PREFIX}/share/examples/hotplug/attach


generic_install_routine:
.for p in ${PROJS}
	@echo "Installing documentation"
	${BSD_INSTALL_DATA_DIR} ${PREFIX}/share/doc/$p
	${BSD_INSTALL_DATA} $p/LICENSE ${PREFIX}/share/doc/$p/
	-${BSD_INSTALL_DATA} $p/doc/* ${PREFIX}/share/doc/$p/

#	@echo "Installing script"
#	-${BSD_INSTALL_SCRIPT} $p/$p ${PREFIX}/sbin/
.endfor
