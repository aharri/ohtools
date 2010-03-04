<?php
/*
 * Copyright (c) 2010 Antti Harri <iku@openbsd.fi>
 *
 * Example URL:
 *
http://www.moposport.fi:8080/workspace.client_moposport/PublishedService?frontpage=true&theme=2
http://www.moposport.fi:8080/workspace.client_moposport/PublishedService?file=&pageID=3&action=view&groupID=1288&OpenGroups=2661,1288
 *
 * Remember to enable fetching of URLs, can be overridden from
 * command line like so: "php -d allow_url_fopen=on moposport.php $urls"
 *
 * Also remember to use a large value for memory_limit. You can
 * override that on command line as well: "-d memory_limit=256M".
 */
require "simple_html_dom.php";
require "parse.php";
require "url.php";

if ($argc <= 2) {
	die("Give two URLs as parameter\n");
}

$urls = $argv;
// Remove script name (moposport.php) from the list
array_shift($urls);
// The first needs to be done before all other URLs.
$catlink = array_shift($urls);

$str = sprintf("Starting scrape\nMagic URL: %s\n", $catlink);
fwrite(STDERR, $str);

// Open the first page so the server will let us open
// pages under that. Server tracks that via session cookie.
$ch = curl_init();
curl_setopt($ch, CURLOPT_HEADER, 0);
curl_setopt($ch, CURLOPT_COOKIEFILE, "cookiefile");
curl_setopt($ch, CURLOPT_COOKIEJAR, "cookiefile");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

curl_setopt($ch, CURLOPT_URL, $catlink);
curl_exec($ch);
curl_close($ch);

foreach ($urls as $url) {
	parse($url);
}

?>
