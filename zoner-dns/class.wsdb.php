<?php

/*
 * Copyright (c) 2009
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

/*
 * SQL
 */
class wsdb_init
{
	public static $db=false;

	static function openDBConnection() {
		if(!self::$db instanceof wsdb) {
			try {
				self::$db = new wsdb(SQL_HOST, SQL_USER, SQL_PASSWD, SQL_DB, SQL_TYPE);
			} catch(Exception $e) {
				die($e->getMessage());
			}
		}
		return self::$db;
	}
}
function db() {
	return wsdb_init::openDBConnection();
}

class wsdb extends db
{
	public $prefix;

	public function Param($str)
	{
		return '?';
	}

	/*
	 * Gets all returned objects, converts them into
	 * array like AdoDB and discards the results.
	 */
	public function GetAll($query, $inputarr=false) {
		$rs = $this->prepare($query);
		if ($inputarr && is_array($inputarr)) {
			foreach ($inputarr as $k=>$v) {
				$rs->set($v);
			}
		}
		$rs->execute();
		$arr = array();
		foreach ($rs->fetchAll() as $obj) {
			$item = array();
			foreach ($obj as $k=>$v) {
				$item[$k]=$v;
			}
			$arr[] = $item;
		}
		return $arr;
	}

	/*
	 * Gets all returned objects, converts them into
	 * array like AdoDB and discards the results.
	 * Unlike GetAll this only returns the first item.
	 */
	public function GetRow($query, $inputarr=false) {
		$arr = $this->GetAll($query, $inputarr);
		return reset($arr);
	}
	public function set_prefix($prefix)
	{
		$this->prefix = $prefix;
	}
	/*
	 * Log queries.
	 */
	public function execute($query)
	{
		debugline($query);
		return parent::execute($query);
	}
	public function prepare($query)
	{
		debugline($query);
		return parent::prepare($query);
	}
	public function exec($query)
	{
		debugline($query);
		return parent::exec($query);
	}
	/*
	 * Helper to get current DB version
	 */
	private function version()
	{
		try {
			$query = 
			("
				select `name`,`value` from `".db()->prefix."config`
				where `name`='sql_version'
				limit 1
			");
			$rs = self::execute($query);
			$obj = $rs->current();
			return isset($obj->value)?$obj->value:-1;
		} catch (Exception $e) {}
		return -1;
	}
	/*
	 * Check that the DB is the right format.
	 */
	private function check()
	{
		$cur = self::version();

		if ($cur != SQL_VERSION)
			return false;
		return true;
	}
	/*
	 * Check and upgrade if necessary.
	 */
	public function verify()
	{
		if (self::check())
			return true;

		$cur = self::version();
		for ($i=$cur+1; $i<SQL_VERSION+1; $i++) {
			if (!is_file(SQL_PATCHES."/{$i}.sql")) {
				throw new Exception('SQL version mismatch, no patches available.');
			}
			// Patch is available.
			self::BeginTrans();
			$patches = file_get_contents(SQL_PATCHES."/{$i}.sql");
			$patches = str_replace(array('$$DB$$', '$$PREFIX$$'), array(SQL_DB, SQL_PREFIX), $patches);
			$patches = explode(';', $patches);
			foreach ($patches as $patch) {
				$patch = trim($patch);
				if (empty($patch))
					continue;
				self::exec($patch);
			}
			$rs = self::prepare("update `".db()->prefix."config` set `value`=".self::Param('a')." where `name`='sql_version' limit 1");
			$rs->set($i);
			$rs->execute();
			self::CommitTrans();
			$cur++;
		}
		if (!self::check())
			throw new Exception(sprintf('SQL version mismatch, want %s, got %s', SQL_VERSION, $cur));
		self::execute
		("
			insert into `".db()->prefix."logs` (`level`, `msg`)
			values ('debug', 'Succesfully upgraded to SQL patch level ".SQL_VERSION."')
		");
	}
}

?>
