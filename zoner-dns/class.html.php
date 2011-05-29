<?php

/*
 * Copyright (c) 2006,2007,2009
 * Antti Harri / OpenHosting Harri <iku@openbsd.fi>
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

class html
{
	public function trydata()
	{
		$args=func_get_args();
		if(empty($args)) return true;

		foreach($args as $k=>$v) {
			// We are looking for an array
			if (strpos($v, '[]') === strlen($v)-2) {
				$v=str_replace('[]', '', $v);
				if (!isset($_REQUEST[$v]) || !is_array($_REQUEST[$v]))
					return false;
				continue;
			}
			if (!isset($_REQUEST[$v]))
				return false;
		}
		return true;
	}

	public function tryfiles()
	{
		$args=func_get_args();
		if(empty($args)) return true;

		foreach($args as $k=>$v) {
			if (!isset($_FILES[$v]['name']) || !is_readable($_FILES[$v]['tmp_name']) || $_FILES[$v]['size'] == 0)
				return false;
		}
		return true;
	}

	/*
	 * Our own little converter for html -> email conversions.
	 */
	static public function _h1($match)
	{
		$match = reset($match);
		$match = strip_tags($match);
		$len = strlen(utf8_decode($match));
		for ($i=0, $gen="$match\n"; $i<$len; $i++)
			$gen.='=';
		return "$gen\n\n";
	}

	static public function to_email($input)
	{
		// Headers
		$input = preg_replace_callback('#\<h1\>(.*)\</h1\>#U', 'html::_h1', $input);
		// Line breaks and paragraphs
		$input = str_replace(array('<br>', '</p>'), array("\n", "\n\n"), $input);
		// Strip rest of the tags
		$input = strip_tags($input);
		// Convert special chars
		$input = html_entity_decode($input);
		// Wordwrap at 72 chars and trim the result
		$input = trim(wordwrap($input, 72));
		return $input;
	}
}
?>
