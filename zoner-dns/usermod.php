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
 */

require 'zoner-config.php';
require 'zoner-functions.php';

sql_connect();

if ($argc <= 1) {
	die($argv[0].": init|add\n");
}

$mode = $argv[1];

switch ($mode)
{
	case "init":
		try {
			$rs = db()->prepare
			("
				create table `".db()->prefix."dyndns`
				(
					id integer primary key,
					user text,
					pass text,
					fqdn text,
					oldip text,
					newip text
				)
			");
			$rs->execute();
		} catch (Exception $e) {
			print ($e->getmessage());
		}
	break;
	case "add":
		$user = read_stdin("Enter username: ");
		$pass = read_stdin("Enter password: ");
		$fqdn = read_stdin("Enter full hostname: ");
		do {
			$ans = 'no';
			$ans = read_stdin("\n\nUser: $user\nPass: $pass\nHost: $fqdn\n\nIs this correct (yes/no)? ");
			$ans = strtolower($ans);
		} while ($ans != 'no' && $ans != 'yes');
		if ($ans == 'yes') {
			try {
				$rs = db()->prepare
				("
					insert into `".db()->prefix."dyndns`
					(`user`, `pass`, `fqdn`) values
					(".db()->param('a').",".db()->param('b').",".db()->param('c').")
				");
				$rs->set($user);
				$rs->set(crypt($pass, '$1$'));
				$rs->set($fqdn);
				$rs->execute();
			} catch (Exception $e) {
				print ($e->getmessage());
			}
		}
	break;
}

?>
