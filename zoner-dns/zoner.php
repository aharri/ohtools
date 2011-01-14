<?php
/*
 * Copyright (c) 2010,2011 Antti Harri <iku@openbsd.fi>
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
 * Zoner uses Direct Admin:
 *  - HTTP code 200 means error on POST
 *  - HTTP code 302 means success on POST
 *  - First we log in and save cookie
 *  - Then we add the new entry
 *  - Delete the old one
 *  - Logout
 */
require "zoner-config.php";
require "zoner-functions.php";
require "class.html.php";

// Check for SSL.
if ($zoner['ssl'] && !ssl_is_enabled())
	error('unknown : request blocked, use https');

// Get the authentication data that client provided.
if (!isset($_SERVER['PHP_AUTH_USER']) || !isset($_SERVER['PHP_AUTH_PW']))
	error('badauth');

// Get new IP that client provided and check for its valididity.
if (!html::trydata('hostname', 'myip') || !filter_var($_REQUEST['myip'], FILTER_VALIDATE_IP))
	error('unknown : bad parameters');

// fqdn
$fqdn  = $_REQUEST['hostname'];
$newip = $_REQUEST['myip'];

$user  = $_SERVER['PHP_AUTH_USER'];
$pass  = $_SERVER['PHP_AUTH_PW'];

$url['login'] = 'https://www25.zoner.fi:2222/CMD_LOGIN';
$url['logout'] = 'https://www25.zoner.fi:2222/CMD_LOGOUT';
$url['ctl'] = 'https://www25.zoner.fi:2222/CMD_DNS_CONTROL';

sql_connect();

if (!check_auth($fqdn, $user, $pass))
	die('badauth');


try {
	// Get the previously new, and soon to become
	// old IP.
	$rs = db()->prepare
	("
		select `newip`
		from `".db()->prefix."dyndns`
		where
			`user` = ".db()->param('a')." and
			`fqdn` = ".db()->param('b')."
		limit 1
	");
	$rs->set($user);
	$rs->set($fqdn);
	$rs->execute();
	$oldip = $rs->current()->newip;

	if ($oldip == $newip) {
		die("nochg ".$oldip);
	}

	// Needs "limit 1" but is unsupported in Sqlite at Zoner.
	$rs = db()->prepare
	("
		update `".db()->prefix."dyndns`
		set
			`oldip` = `newip`,
			`newip` = ".db()->param('a')."
		where
			`user`= ".db()->param('b')." and
			`fqdn`= ".db()->param('c')."
	");
	$rs->set($newip);
	$rs->set($user);
	$rs->set($fqdn);
	$rs->execute();
	if ($rs->Affected_Rows() < 1) {
		die("nochg ".$oldip);
	}
	update_zoner_da($fqdn, $oldip, $newip);
	print("good ".htmlentities($newip));
} catch (Exception $e) {
	print ("911");
}

?>
