<?php

/*
 * Copyright (c) 2010 Antti Harri <iku@openbsd.fi>
 *
 */

function determine_filename($path, &$file)
{
	$i = 0;
	$try = $file;
	do {
		if (!file_exists($path.'/'.$try)) {
			$file = $try;
			return $path.'/'.$try;
		}
		$i++;
		$try = $i.'_'.$file;
	} while (true);
}

function parse($url)
{
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_HEADER, 0);
	curl_setopt($ch, CURLOPT_COOKIEFILE, "cookiefile");
	curl_setopt($ch, CURLOPT_COOKIEJAR, "cookiefile");
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
	
	curl_setopt($ch, CURLOPT_URL, $url);
	$html = curl_exec($ch);
	file_put_contents('data', $html);

	$str = sprintf("url %s\n", $url);
	fwrite(STDERR, $str);

	$html = str_get_html($html);

	// Recurse into these.
	$groups = $html->find('ul.ryhmat li a');
	foreach ($groups as $group) {
		$item['text'] = isset($group->plaintext)?$group->plaintext:'';
		$item['text'] = html_entity_decode($item['text']);
		$item['link'] = isset($group->href)?$group->href:'';
		// URLs are relative, resolve before using.
		global $catlink;
		$item['link'] = resolve_href($catlink, $item['link']);
		$item['link'] = html_entity_decode($item['link']);
		$str = print_r($item, true);
		fwrite(STDERR, $str);
		parse($item['link']);

		// $group is no longer used, clean up the refs.
		$group->clear();
		unset($group);
	}

	// Get category path to be used for product names for
	// products that only have product ID.
	$catparts = $html->find('h2 a');
	$catpath = array();
	foreach ($catparts as $catpart) {
		$catpath[] = $catpart->plaintext;
	}
	$catpath = implode(', ', $catpath);

	// Parse data from these.
	$areas = $html->find('map area');

	if (count($areas) == 0) {
		// $html is no longer used, clean up the refs.
		$html->clear();
		unset($html);

		curl_close($ch);
		return true;
	}

	// Image map exists, so there must be an image too.

	// Find image and store it on the disc.
	$partimg = $html->find('img[usemap=#parts]', 0)->src;

	// $html is no longer used, clean up the refs.
	$html->clear();
	unset($html);

	$handle = fopen($partimg, "rb");
	$img = stream_get_contents($handle);
	fclose($handle);

	$partimg = basename($partimg);
	$handle = fopen(determine_filename('images', $partimg), 'wb');
	fwrite($handle, $img);
	fclose($handle);

	// Process image maps.
	foreach ($areas as $area) {
		// XXX: isset()
		$temp = preg_replace("/.*\('(.*)',\s*'(.*)'\)/", '$1,$2', $area->onclick);
		list($partno, $catno) = explode(',', $temp);
		$parts = explode(';', $partno);
		foreach ($parts as $part)
			$items[$part] = $part;
		// $area is no longer needed, clean up the refs.
		$area->clear();
		unset($area);
	}

	// Split into chunks to prevent overflowing the query
	// part of the URL.
	$temp = array();
	$temp2 = array();
	$i = 0;
	foreach ($items as $item) {
		$temp[$item] = $item;
		if (++$i >= 20) {
			$temp2[] = $temp;
			$temp = array();
			$i = 0;
		}
	}
	if (count($temp) > 0)
		$temp2[] = $temp;
	$items = $temp2;

	$str = sprintf("Part category number: %d\n", $catno);
	$str .= sprintf("Found parts:\n");
	$str .= print_r($items, true);
	$str .= sprintf("Querying server for part info.\n");
	fwrite(STDERR, $str);

	foreach ($items as $chunk) {
		$purl = sprintf("http://www.moposport.fi:8080/workspace.client_moposport/getpart.jsp?partnro=%s&fullpartid=%s", implode(';', $chunk), $catno);
		fwrite(STDERR, $purl."\n");
		curl_setopt($ch, CURLOPT_URL, $purl);
		$qhtml = curl_exec($ch);
// 		$qhtml = file_get_contents('parts');
		$qhtml = str_get_html($qhtml);
		$blocks = $qhtml->find('p');
		unset($item);
		foreach ($blocks as $block) {
			// Input is CRLF terminated iso-8859-1 text.
			$item['name'] = iconv('iso-8859-1', 'utf-8', $block->children(0)->plaintext);
			$item['code'] = iconv('iso-8859-1', 'utf-8', preg_replace('/.*Tuotekoodi: (.*)<br>Hinta.*/', '$1', str_replace("\r\n", " ", $block->innertext)));
			$item['price'] = iconv('iso-8859-1', 'utf-8', preg_replace('/.*Hinta: (.*) EUR<br>.*/', '$1', str_replace("\r\n", " ", $block->innertext)));
			$item['img'] = $partimg;
			// Reset vars if item is not available.
			if (preg_match("/Tuote.*ei ole.*saatavissa/", $item['code'])) {
				$item['code'] = $item['name'];
				$item['name'] = $catpath;
				$item['price'] = 0;
			}
			printf("%s\t%s\t%s\t%s\n", $item['code'], $item['name'], $item['price'], $item['img']);
		}
	}
	curl_close($ch);
}
?>
