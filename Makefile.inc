# Makefile for Openhosting's tools collection

# Remember to bump the number inside openbsd-port/Makefile too.
V=2.1.5

PORTSDIR ?=	/usr/ports
SYSCONFDIR =	/etc
DESTDIR ?=
PREFIX ?=	/usr/local
LOCALBASE ?=	/usr/local
DATADIR = 	${PREFIX}/share/ohtools
EXAMPLES =	${PREFIX}/share/examples/ohtools

INSTALL_DATA_DIR =	install -d -o root -g bin -m 755
INSTALL_PROGRAM_DIR =	install -d -o root -g bin -m 755
INSTALL_SCRIPT_DIR =	install -d -o root -g bin -m 755
INSTALL_DATA =		install -c -o root -g bin -m 444
INSTALL_PROGRAM =	install -c -s -o root -g bin -m 555
INSTALL_SCRIPT =	install -c -o root -g bin -m 555
