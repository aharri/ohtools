# Makefile for Openhosting's tools collection

PROJS=\
	baseup
#	chroot_objects
#	tempy
#	check_errata
#	hotplug
#	mbox_pruner


SYSCONFDIR=/etc
PREFIX?=/usr/local
DP=${DESTDIR}${PREFIX}

.PHONY: ${PROJS}

install: generic_install_routine ${PROJS}

baseup:
	@echo "Installing project specific files"
	@echo ${BSD_INSTALL_SCRIPT} $@/functions.sh ${DP}/libexec/baseup_functions.sh
	@echo perl -pi -e "s,^(CONFIG=).*,\1${SYSCONFDIR}/baseup.conf," ${DP}/sbin/$@
	@echo perl -pi -e "s,^(FUNCS=).*,\1${DP}/libexec/baseup_functions.sh," ${DP}/sbin/$@
	@echo perl -pi -e "s,^(TEMPS=).*,\1/var/tmp/$@/," ${DP}/sbin/$@

generic_install_routine:
.for p in ${PROJS}
	@echo "Installing documentation"
	@echo ${BSD_INSTALL_DATA_DIR} ${DP}/share/doc/$p
	@echo ${BSD_INSTALL_DATA} $p/LICENSE ${DP}/share/doc/$p/
	@-echo ${BSD_INSTALL_DATA} $p/doc/* ${DP}/share/doc/$p/

	@echo "Installing script"
	@echo ${BSD_INSTALL_SCRIPT} $p/$p ${DP}/sbin/
.endfor
