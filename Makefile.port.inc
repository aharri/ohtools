dist:
	mkdir dist/

dist/ohtools-${V}.tar.gz:
	git archive --prefix=ohtools-"${V}"/ HEAD | gzip > dist/ohtools-"${V}".tar.gz

distfile: dist dist/ohtools-${V}.tar.gz

${PORTSDIR}/infrastructure:
	@echo "You need to have ports directory. Refer to OpenBSD's documentation."
	@exit 1

package: ${PORTSDIR}/infrastructure distfile
	if [ ! -e "${PORTSDIR}/mystuff/sysutils" ]; then \
		mkdir -p "${PORTSDIR}/mystuff/sysutils"; \
	fi
	if [ -e "${PORTSDIR}/mystuff/sysutils/ohtools.orig" ]; then \
		echo "${PORTSDIR}/mystuff/sysutils/ohtools.orig exists, removing it."; \
		rm -rf "${PORTSDIR}/mystuff/sysutils/ohtools.orig"; \
	fi
	-mv "${PORTSDIR}/mystuff/sysutils/ohtools/" "${PORTSDIR}/mystuff/sysutils/ohtools.orig/"
	cp -f dist/ohtools-${V}.tar.gz "${PORTSDIR}/distfiles/"
	cp -r openbsd-port "${PORTSDIR}/mystuff/sysutils/ohtools"
	( \
		cd "${PORTSDIR}/mystuff/sysutils/ohtools" && \
		make makesum && \
		make clean && \
		make repackage \
	)

update: package
	cd "${PORTSDIR}/mystuff/sysutils/ohtools" && make reinstall
