/* $Id: realpath.c,v 1.1 2007/09/30 00:44:30 iku Exp $ */
/* Copyright (c) 2007 Antti Harri <iku@openbsd.fi> */

#include <stdio.h>
#include <sys/param.h>
#include <stdlib.h>

void usage()
{
	printf ("Usage: realpath path\n");
	exit(1);
}
int main (int argc, char *argv[])
{
	char path[PATH_MAX];
	char *ptr;

	// Usage.
	if (argc<=1) usage();

	// Get canonical path.
	ptr=realpath(argv[1], path);
	if (!ptr) {
		return 1;
	}

	// Print results.
	printf ("%s\n", ptr);
	
	return 0;
}
