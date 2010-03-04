<?php

/* 
From http://fi.php.net/realpath
Isaac Z. Schlueter i at foohack dot com
28-Aug-2008 02:02
*/
function resolve_href ($base, $href) {

    // href="" ==> current url.
    if (!$href) {
        return $base;
    }

    // href="http://..." ==> href isn't relative
    $rel_parsed = parse_url($href);
    if (array_key_exists('scheme', $rel_parsed)) {
        return $href;
    }

    // add an extra character so that, if it ends in a /, we don't lose the last piece.
    $base_parsed = parse_url("$base ");
    // if it's just server.com and no path, then put a / there.
    if (!array_key_exists('path', $base_parsed)) {
        $base_parsed = parse_url("$base/ ");
    }

    // href="/ ==> throw away current path.
    if ($href{0} === "/") {
        $path = $href;
    } else {
        $path = dirname($base_parsed['path']) . "/$href";
    }

    // bla/./bloo ==> bla/bloo
    $path = preg_replace('~/\./~', '/', $path);

    // resolve /../
    // loop through all the parts, popping whenever there's a .., pushing otherwise.
        $parts = array();
        foreach (
            explode('/', preg_replace('~/+~', '/', $path)) as $part
        ) if ($part === "..") {
            array_pop($parts);
        } elseif ($part!="") {
            $parts[] = $part;
        }

	$host = array_key_exists('scheme', $base_parsed)?$base_parsed['scheme'].'://'.$base_parsed['host'] : "";
	$port = array_key_exists('port', $base_parsed)?':'.$base_parsed['port']:'';
    return $host.$port."/".implode("/", $parts);

}

?> 