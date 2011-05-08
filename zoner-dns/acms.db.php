<?php
/**
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Copyright (C)
 * 2006 Joni Halme <jontsa@angelinecms.info>
 *
 * The Initial Developer of the Original Code is
 * Joni Halme <jontsa@angelinecms.info>
 *
 * Portions created by the Initial Developer are Copyright (C) 2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * 2007 Jorma Tuomainen <jt@wiza.fi>
 * 2008 Tarmo Hyvarinen <th@angelinecms.info>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 */
/**
 * AdoDB compatible database library.
 *
 * Currently DB implements
 * Execute() (bulk binding not supported), Prepare() UpdateBlob(), Affected_Rows(), Insert_ID(),
 * BeginTrans(), RollbackTrans(), CommitTrans(), transCnt
 * and DB_ResultSet implements
 * RecordCount(), MoveNext(), FetchObj(), FetchNextObj(), fields, EOF
 *
 * Fun fact: AdoDB required approximately 4500 lines of code (with comments) to work, this class requires about
 * 500 lines including comments (about 250 lines without comments).
 * Fun fact 2: Switching from AdoDB to DB-class dropped memory_get_usage() by 0.8 megabytes !!
 *
 * @package    Kernel
 * @subpackage DB
 * @author     Joni Halme <jontsa@angelinecms.info>
 */
class DB {

	/**
	 * Instance of PDO.
	 * @access private
	 * @var    PDO
	 */
	private $conn;

	/**
	 * Amount of rows the last INSERT, UPDATE, DELETE query affected.
	 * @access private
	 * @var    int
	 */
	private $affectedrows=0;

	/**
	 * Amount of not commited/rollbacked transactions started with beginTrans().
	 * @access private
	 * @var    int
	 */
	private $transcnt=0;

	/**
	 * Number of SQL queries executed.
	 * @static
	 * @access public
	 * @var    int
	 */
	static public $querycount=0;

	private $dbconn;

	/**
	 * Constructor opens connection to database using PDO.
	 *
	 * @access public
	 * @param  string $server SQL server. defaults to localhost
	 * @param  string $user Username at SQL server
	 * @param  string $pass Password at SQL server or false if none
	 * @param  string $database Database to select
	 * @param  string $dbconn Database type (mysql,sqlite etc). Defaults to mysql
	 * @param  mixed $sqlitedb Optional path to SQLite database
	 * @param  bool $pconn Use persistent connection? Defaults to false
	 * @uses   PDO
	 * @uses   Common_Exception
	 */
	function __construct($server="localhost",$user,$pass=false,$database=false,$dbconn="mysql",$pconn=false) {
		if(!class_exists("PDO")) {
			die("AngelineCMS requires PDO support. Please recompile PHP with PDO (see www.php.net/pdo).");
		} elseif($dbconn=="sqlite"&&(file_exists($database)&&!is_readable($database))) {
			die("Selected SQLite database is not readable. Please check your database settings.");
		}
		switch($dbconn) {
			case "mysql":
				$dsn="mysql:host={$server};dbname={$database}";
				break;
			case "sqlite":
				$dsn="sqlite:{$database}";
				break;
			case "postgres":
				$dsn="pgsql:host={$server} port=5432 dbname={$database} user={$user} password={$pass}";
				break;
			case "firebird":
				$dsn="firebird:dbname={$server}:{$database}";
				break;
			default:
				throw new Common_Exception("Unsupported database type. Can't create database connection.");
		}
		$this->dbconn=$dbconn;
		try {
			if($dbconn!="firebird") {
				$this->conn=new PDO($dsn,$user,$pass,array(PDO::ATTR_PERSISTENT=>(bool)$pconn));
			} else {
				$this->conn=new PDO($dsn,$user,$pass);
			}
			$this->conn->setAttribute(PDO::ATTR_ERRMODE,PDO::ERRMODE_EXCEPTION);
			if($dbconn=="sqlite") {
				$this->conn->setAttribute(PDO::ATTR_TIMEOUT,60);
			}
		} catch(Exception $e) {
			DEBUG($e->getMessage());
			throw new Common_Exception("Connection to database failed.");
		}
	}

	/**
	 * Class member get overload method.
	 *
	 * Currently supported is transCnt.
	 *
	 * @access private
	 * @param  string $k
	 * @return mixed
	 */
	public function __get($k) {
		switch($k) {
			case "transCnt":
				return $this->transcnt;
		}
		throw new Common_Exception("Program tried to access a non-existant member ".__CLASS__."::{$k}.");
	}

	/**
	 * Executes SQL query and returns results in DB_ResultSet object.
	 *
	 * @access public
	 * @param  string $query SQL query
	 * @return DB_ResultSet
	 * @uses   Common_Exception
	 * @uses   DB_ResultSet
	 */
	public function execute($query) {
		$this->affectedrows=0;
		try {
			$stmt=$this->conn->query($query);
			if($this->dbconn!="firebird") {
				$this->affectedrows=$stmt->rowCount();
			}
			self::$querycount++;
			return new DB_ResultSet($stmt,true);
		} catch(Exception $e) {
			DEBUG("db()->execute({$query})",$e->getMessage());
			throw new Common_Exception("SQL query failed.");
		}
	}

	/**
	 * Prepares an SQL query without executing it.
	 *
	 * Use this method when you want to insert variables other than strings to database.
	 * It is also usefull when you need to make same query multiple times with different values.
	 *
	 * @access public
	 * @param  string $query SQL query
	 * @return DB_ResultSet
	 * @uses   DB_ResultSet
	 * @uses   Common_Exception
	 */
	public function prepare($query) {
		$this->affectedrows=0;
		if(empty($query)) {
			throw new Common_Exception("Empty SQL query can't be executed.");
		}
		try {
			return new DB_ResultSet($this->conn->prepare($query));
		} catch(Exception $e) {
			DEBUG($e->getMessage());
			throw new Common_Exception("Preparing SQL query failed.");
		}
	}

	/**
	 * Executes SQL query without returning resultset.
	 *
	 * This method is similar to execute() but instead of returning ResultSet,
	 * it just returns the amount of affected rows and thus is slightly faster when doing INSERT, UPDATE etc queries.
	 *
	 * @access public
	 * @param  string $query SQL query
	 * @return int Number of affected rows
	 * @uses   Common_Exception
	 */
	public function exec($query) {
		$this->affectedrows=0;
		if(empty($query)) {
			throw new Common_Exception("Empty SQL query can't be executed.");
		}
		try {
			$this->affectedrows=$this->conn->exec($query);
			self::$querycount++;
		} catch(Exception $e) {
			DEBUG($e->getMessage());
			throw new Common_Exception("SQL query failed.");
		}
		return $this->affectedrows;
	}

	/**
	 * Returns number of rows last query affected.
	 *
	 * @access public
	 * @return int
	 */
	public function affected_Rows() {
		return $this->affectedrows;
	}

	/**
	 * Returns ID from last INSERT query if database supports it.
	 *
	 * @access public
	 * @return mixed Integer or false on error
	 */
	public function insert_ID() {
		if($this->conn=="postgres") {
			throw new Common_Exception("insert_ID not supported with PostgreSQL, please use RETURNING id");
		}
		try {
			return $this->conn->lastInsertID();
		} catch(Exception $e) {
			throw new Common_Exception(i18n("Unable to retrieve identifier for last insert query."));
		}
	}

	/**
	 * Begins database transaction if database supports it.
	 *
	 * @access public
	 * @uses   Common_Exception
	 */
	public function beginTrans() {
		try {
			$this->conn->beginTransaction();
			$this->transcnt++;
		} catch(Exception $e) {
			DEBUG($e->getMessage());
			throw new Common_Exception("Could not start database transaction.");
		}
	}

	/**
	 * Commits transaction started with beginTrans().
	 *
	 * @access public
	 * @param  bool $ok If false, method automatically calls rollBack() and transaction is not committed
	 * @uses   Common_Exception
	 */
	public function commitTrans($ok=true) {
		if($this->transcnt<1) {
			return;
		}
		try {
			if(!$ok) {
				$this->conn->rollBack();
			} else {
				$this->conn->commit();
			}
			$this->transcnt--;
		} catch(Exception $e) {
			DEBUG($e->getMessage());
			throw new Common_Exception("Could not commit database transaction.");
		}
	}

	/**
	 * Cancels transaction started with beginTrans().
	 *
	 * @access public
	 * @uses   Common_Exception
	 */
	public function rollBackTrans() {
		if($this->transcnt<1) {
			throw new Common_Exception("Program attempted to cancel transaction without starting one.");
		}
		try {
			$this->conn->rollBack();
			$this->transcnt--;
		} catch(Exception $e) {
			DEBUG($e->getMessage());
			throw new Common_Exception("Could not roll back database transaction.");
		}
	}
	
	public static function hash() {
		if(config()->softdelete) {
			$time=time();
			return (string)sha1($time.mt_rand().crypt($time,md5(rand())));
		}
		return "0";
	}

}

/**
 * AdoDB compatible SQL resultset and statement library.
 *
 * @package    Kernel
 * @subpackage DB
 * @author     Joni Halme <jontsa@angelinecms.info>
 * @link       http://adodb.sourceforge.net
 */
class DB_ResultSet implements Iterator {

	/**
	 * Array of rows from executed SQL query.
	 * @var    array
	 */
	private $rows=array();
	
	private $recordCount=0;

	/**
	 * Current row in resultset.
	 * @var    int
	 */
	private $index=0;

	/**
	 * PDOStatement if resultset was created with DB::prepare().
	 * @param  mixed
	 */
	private $stmt=false;

	/**
	* Binding column count
	* @param  int
	*/
	private $column=1;

	/**
	 * Constructor.
	 *
	 * @access public
	 * @param  PDOStatement $stmt Statement from DB
	 * @param  bool $executed If true, rows are read automatically from Statement instead of waiting for execute()
	 * @uses   Common_Exception
	 */
	function __construct($stmt,$executed=false) {
		if($stmt instanceof PDOStatement) {
			if($executed) {
				// This should fix problems with MySQL. PHP bug #42322
				if($stmt->columnCount()) {
					$this->rows=$stmt->fetchAll(PDO::FETCH_OBJ);
					$this->recordCount=count($this->rows);
				}
			} else {
				$this->stmt=$stmt;
			}
		} else {
			throw new Common_Exception("Can't create SQL resultset. Invalid parameters.");
		}
	}

	/**
	 * Member get overload method.
	 *
	 * Currently supports fields array and EOF boolean.
	 *
	 * @access private
	 * @return mixed
	 */
	public function __get($k) {
		switch($k) {
			case "fields":
				if(isset($this->fields)) {
					return $this->fields;
				} elseif(isset($this->rows[$this->index])) {
					$this->fields=array();
					foreach($this->rows[$this->index] as $k=>$v) {
						$this->fields[$k]=$v;
					}
					return $this->fields;
				}
				return array();
			case "EOF":
				return ($this->index>=$this->recordCount);
		}
	}

	public function set($value,$key=false) {
		if($this->stmt) {
			if(!$key) $key=$this->column++;
			$this->stmt->bindValue($key,$value);
			return $this;
		}
		throw new Common_Exception(i18n("Program attempted to set parameter to an executed SQL query."));
	}
	
	public function setLob($value,$key=false) {
		if($this->stmt) {
			if(!$key) $key=$this->column++;
			$this->stmt->bindValue($key,$value,PDO::PARAM_LOB);
			return $this;
		}
		throw new Common_Exception(i18n("Program attempted to set parameter to an executed SQL query."));
	}
	
	public function hash($key=false) {
		if($this->stmt) {
			if(!$key) $key=$this->column++;
			$this->stmt->bindValue($key,DB::hash());
			return $this;
		}
		throw new Common_Exception(i18n("Program attempted to set hash to an executed SQL query."));
	}
	
	public function bind(&$value,$key=false) {
		if($this->stmt) {
			if(!$key) $key=$this->column++;
			$this->stmt->bindParam($key,$value);
			return $this;
		}
		throw new Common_Exception(i18n("Program attempted to bind parameter to an executed SQL query."));
	}
	
	public function bindLob($value,$key=false) {
		if($this->stmt) {
			if(!$key) $key=$this->column++;
			$this->stmt->bindParam($key,$value,PDO::PARAM_LOB);
			return $this;
		}
		throw new Common_Exception(i18n("Program attempted to bind parameter to an executed SQL query."));
	}

	/**
	 * Binds variable to prepared query.
	 *
	 * Used when resultset is created with DB::prepare():
	 *
	 * @access public
	 * @param  int $col Column number
	 * @param  mixed $var Value for column
	 * @param  int $type PDO variable type (PDO::PARAM_INT, PARAM_STR, PARAM_LOB, PARAM_NULL)
	 * @uses   Common_Exception
	 */
	public function bindParam($col,$var,$type=PDO::PARAM_STR) {
		DEBUG("DEPRECATED!!! stop using bindParam()");
		if($this->stmt) {
			try {
				$this->stmt->bindParam($col,$var,$type);
			} catch(Exception $e) {
				DEBUG($e->getMessage());
				throw new Common_Exception("Binding parameter to SQL query failed.");
			}
		} else {
			throw new Common_Exception("Program attempted to bind parameter to an executed SQL query.");
		}
	}

	/**
	 * Executes a prepared query.
	 *
	 * After this, you can use resultset as you would have called it via DB::execute().
	 *
	 * @access public
	 * @uses   Common_Exception
	 * @uses   DB
	 */
	public function execute() {
		if($this->stmt) {
			try {
				$this->stmt->execute();
				unset($this->fields);
				if($this->stmt->columnCount()) {
					$this->rows=$this->stmt->fetchAll(PDO::FETCH_OBJ);
				} else {
					$this->rows=array();
				}
				$this->index=0;
				$this->recordCount=count($this->rows);
				$this->column=1;
			} catch(Exception $e) {
				DEBUG($e->getMessage());
				throw new Common_Exception("Executing a prepared query failed.");
			}
			DB::$querycount++;
		} else {
			throw new Common_Exception("Program attempted to execute query twice.");
		}
		return $this;
	}

	/**
	 * Returns number of rows in resultset.
	 *
	 * @access public
	 * @return int
	 */
	public function recordCount() {
		return $this->recordCount;
	}

	/**
	 * Moves internal row pointer forward.
	 *
	 * @access public
	 * @return bool True on success, false if there are no more rows
	 */
	public function moveNext() {
		if($this->index<$this->recordCount) {
			$this->index++;
			unset($this->fields);
			return true;
		}
		return false;
	}

	/**
	 * Returns current row as an stdClass object.
	 *
	 * @access public
	 * @return mixed stdClass or false if there are no rows
	 */
	public function fetchObj() {
		if(isset($this->rows[$this->index])) {
			return clone $this->rows[$this->index];
		} else {
			return false;
		}
	}

	/**
	 * Returns current row as an object and moves internal row pointer.
	 *
	 * When last row is read from resultset, fetchNextObj() returns false.
	 *
	 * @access public
	 * @return mixed stdClass or false if there are no rows or last row has been reached
	 */
	public function fetchNextObj() {
		$tmp=$this->fetchObj();
		$this->moveNext();
		return $tmp;
	}
	
	public function fetchAll() {
		return $this->rows;
	}

	public function current() {
		return $this->fetchObj();
	}

	public function key() {
		return $this->index;
	}

	public function next() {
		$this->moveNext();
	}

	public function rewind() {
		$this->index=0;
	}

	public function seek($position) {
		$this->index=$position;
	}

	public function valid() {
		return isset($this->rows[$this->index]);
	}

	public function affected_Rows() {
		return $this->stmt->rowCount();
	}
}
?>
