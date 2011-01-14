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
 */
function error($msg="Argh! Yarrr!\n")
{
	$str = sprintf($msg);
	fwrite(STDERR, $str);
	die();
}

function run_curl($url, $postfields=NULL)
{
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_HEADER, 1);
	curl_setopt($ch, CURLOPT_COOKIEFILE, "zoner-cookiefile");
	curl_setopt($ch, CURLOPT_COOKIEJAR, "zoner-cookiefile");
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
	curl_setopt($ch, CURLOPT_CAINFO, 'ca/ca-bundle.crt');
	if (is_array($postfields)) {
		curl_setopt($ch, CURLOPT_POST, true);
		curl_setopt($ch, CURLOPT_POSTFIELDS, $postfields);
	}
	curl_setopt($ch, CURLOPT_URL, $url);
	$html = curl_exec($ch);
	if ($html === false)
	{
		fwrite(STDERR, curl_error($ch)."\n");
	}
	curl_close($ch);

	// Parse HTTP code
	preg_match('#^HTTP/1\.1 ([0-9]{3}) .*#', $html, $matches);

	$code = isset($matches[1])?$matches[1]:0;

	return $code;
}

// To get debug use this. 
// function debugline($msg) { print($msg); }
function debugline($msg) { }
function DEBUG($msg){ }

function ssl_is_enabled()
{
	if (!isset($_SERVER['HTTPS']) || $_SERVER['HTTPS'] != 'on') {
		return false;
	}
	return true;
}

/*
 * SQL
 */
function sql_connect()
{
	require('acms.db.php');
	require('class.wsdb.php');
	try {
		if (SQL_TYPE != 'sqlite')
			db()->execute('set character set utf8');
		db()->set_prefix(SQL_PREFIX);
	} catch (Exception $e) {
		die($e->getmessage());
	}
}

function check_auth($fqdn, $user, $pass)
{
	try {
		$rs = db()->prepare
		("
			select *
			from `".db()->prefix."dyndns`
			where
				`fqdn` = ".db()->param('a')." and
				`user` = ".db()->param('b')."
			limit 1
		");
		$rs->set($fqdn);
		$rs->set($user);
		$rs->execute();
		$obj = $rs->fetchObj();
		if ($obj->password == crypt($pass, $obj->password)) {
			return true;
		} else {
			return false;
		}
	} catch (Exception $e) {
		die($e->getmessage());
	}
	return false;
}
#function DEBUG($msg){ print($msg);}
class Common_Exception extends Exception {}

function update_zoner_da($fqdn, $oldip, $newip)
{
	global $zoner;
	global $url;

	// Chop fqdn.
	preg_match('/^(.*)\.(.*)$/U', $fqdn, $matches);
	$host = $matches[1];
	$domain = $matches[2];

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
		throw new Exception("Could not login!\n");
	
	// Add a new record and delete the old one.
	$postfields = array
	(
		'action' => 'add',
		'domain' => $domain,
		'ptr_val' => '',
		'type' => 'A',
		'name' => $host,
		'value' => $newip,
		'add' => 'Add'
	);
	$code = run_curl($url['ctl'], $postfields);
	if ($code != 302)
		throw new Exception("Could not add new entry!\n");
	
	$postfields = array
	(
		'action' => 'select',
		'domain' => $domain,
		// The number in "arecs0" doesn't matter, the value part does.
		'arecs0' => 'name='.urlencode($host).'&value='.urlencode($oldip),
		'delete' => 'Delete Selected'
	);
	$code = run_curl($url['ctl'], $postfields);
	if ($code != 302)
		throw new Exception("Could not delete old entry!\n");
	
	// Log out so Direct Admin doesn't get all confused.
	$code = run_curl($url['logout']);
	if ($code != 302)
		throw new Exception("Could not logout!\n");

}

?>