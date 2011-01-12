<?php
/*
 * Copyright (c) 2011 Antti Harri <iku@openbsd.fi>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
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

?>