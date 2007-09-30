# $Id: Makefile,v 1.1 2007/09/30 00:44:30 iku Exp $
#
# Makefile for realpath.c

PREFIX=/usr/local
OBJS=realpath.o
TARGET=realpath

CC=gcc
CFLAGS=-O2 -Wall
LD=gcc
LDFLAGS=
LIBS=

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(TARGET)

realpath.o: realpath.c
	$(CC) $(CFLAGS) -c realpath.c

#.PHONY : clean
clean:
	rm -f $(OBJS) $(TARGET) $(TARGET).core
