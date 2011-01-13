<?php
/*
 * Copyright (c) 2011 Antti Harri <iku@openbsd.fi>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * Remember to enable fetching of URLs, can be overridden from
 * command line like so: "php -d allow_url_fopen=on zoner.php"
 *
 * Zoner uses Direct Admin:
 *  - HTTP code 200 means error on POST
 *  - HTTP code 302 means success on POST
 *  - First we log in and save cookie
 *  - Then we add the new entry
 *  - Delete the old one
 *  - Logout
 *
 * Install:
 *  - Drop this into zoner's htdocs dir
 *  - Touch and chmod 600 zoner-cookiefile zoner-config.php zoner-dns.db
 *  - Configure zoner-config.php
 *  - Configure ddclient
 *  - Enjoy!
 */
require "zoner-config.php";
require "zoner-functions.php";

if ($argc <= 3) {
	die("Give hostname, old and new IPs as parameter\n");
}
$host = $argv[1];
$oldip = $argv[2];
$newip = $argv[3];

$url['login'] = 'https://www25.zoner.fi:2222/CMD_LOGIN';
$url['logout'] = 'https://www25.zoner.fi:2222/CMD_LOGOUT';
$url['ctl'] = 'https://www25.zoner.fi:2222/CMD_DNS_CONTROL';

$str = sprintf("Starting update:\n\nLogin: %s\nHost: %s\nOld IP: %s\nNew IP: %s\n",
	$zoner['username'].'/*** (not shown)',
	$host.' ('.$zoner['domain'].')',
	$oldip,
	$newip);
fwrite(STDERR, $str);

// Log into Direct Admin
$postfields = array
(
	'username' => $zoner['username'],
	'password' => $zoner['password'],
	// Not needed, but might be at some point?
	// 'referer' => '/CMD&#95zoner'
);
$code = run_curl($url['login'], $postfields);
if ($code != 302)
	error("Could not login!\n");

// Add a new record and delete the old one.
$postfields = array
(
	'action' => 'add',
	'domain' => $zoner['domain'],
	'ptr_val' => '',
	'type' => 'A',
	'name' => $host,
	'value' => $newip,
	'add' => 'Add'
);
$code = run_curl($url['ctl'], $postfields);
if ($code != 302)
	error("Could not add new entry!\n");

$postfields = array
(
	'action' => 'select',
	'domain' => $zoner['domain'],
	// The number in "arecs0" doesn't matter, the value part does.
	'arecs0' => 'name='.urlencode($host).'&value='.urlencode($oldip),
	'delete' => 'Delete Selected'
);
$code = run_curl($url['ctl'], $postfields);
if ($code != 302)
	error("Could not delete old entry!\n");

// Log out so Direct Admin doesn't get all confused.
$code = run_curl($url['logout']);
if ($code != 302)
	error("Could not logout!\n");


?>
