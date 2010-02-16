<?php
/*
 * Copyright (c) 2010 Antti Harri <iku@openbsd.fi>
 *
 * Example URL:
 * http://keltaisetsivut.eniro.fi/palveluntarjoajat/moottoripy%C3%B6r%C3%A4:77475/p:1
 *
 * Remember to enable fetching of URLs, can be overridden from
 * command line like so: "php -d allow_url_fopen=on eniro.php $urls"
 *
 * Also remember to use a large value for memory_limit. You can
 * override that on command line as well: "-d memory_limit=256M".
 */
require("simple_html_dom.php");

if ($argc <= 1) {
	die("Give url as parameter\n");
}

$urls = $argv;
array_shift($urls);
fwrite(STDERR, "Starting scrape\n");
foreach ($urls as $url) {
	if (strpos($url, '/p:') === false)
		$url = preg_replace('#/?$#', '/p:1', $url);
	for ($i=1; $i<100; $i++) {
		$url = preg_replace(',/p:([[:digit:]]+),', "/p:$i", $url);
		$str = sprintf("url %s, page %d\n", $url, $i);
		fwrite(STDERR, $str);
		$html = file_get_html($url);
		$blocks = $html->find('div.company-hit');
		if (count($blocks) == 0)
			break 1;
		// .addax-cs_hl_hit_company_name_click = company name
		// .street-address                     = street address,
		// .locality                           = city,
		// .postal-code                        = postal code,
		// .post-box                           = post box if any,
		// .value                              = phone number,
		foreach ($blocks as $block) {
			$item['name']  = $block->find('a.addax-cs_hl_hit_company_name_click', 0);
			$item['addr']  = $block->find('span.street-address', 0);
			$item['phone'] = $block->find('span.value', 0);
			$item['pcode'] = $block->find('span.postal-code', 0);
			$item['pobox'] = $block->find('span.post-box', 0);
			$item['city']  = $block->find('span.locality', 0);

			foreach ($item as $k => $v) {
				$item[$k] = (isset($v->plaintext))?$v->plaintext:'';
			}
			// Format and output
			// Name, (empty), Street address, Postal-code City, Phone, Postal box
			printf("%s, , %s, %s %s, %s, %s\n", $item['name'], $item['addr'], $item['pcode'], $item['city'], $item['phone'],  $item['pobox']);
			unset($item);
		}
		unset($html);
		unset($blocks);
		unset($block);
	}
}
?>
