SUBDIR +=	baseup
SUBDIR +=	chroot_objects
SUBDIR +=	check_errata
SUBDIR +=	hotplug
SUBDIR +=	pkgpurge
SUBDIR +=	mailtail

all:		${SUBDIR}
install:	${SUBDIR}
	${INSTALL_DATA_DIR} ${DESTDIR}${DATADIR}
	${INSTALL_DATA_DIR} ${DESTDIR}${EXAMPLES}
	${INSTALL_DATA} LICENSE ${DESTDIR}${DATADIR}

TARGETS=${.TARGETS}

.if defined(SUBDIR)
${SUBDIR}::
	@set -e; \
	DIR=${.TARGET}; \
	echo "===> $${DIR}"; \
	cd "${.CURDIR}/$${DIR}"; \
	exec ${MAKE} ${MAKE_FLAGS} SUBPROJ="$${DIR}" ${TARGETS}
.endif

.include "Makefile.inc"
