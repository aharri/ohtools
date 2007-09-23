#!/usr/local/bin/php
<?php
/*
 * $Id: prune.php,v 1.4 2007/09/23 20:37:10 iku Exp $
 *
 * Copyright (c) 2007 Antti Harri <iku@openbsd.fi>
 *
 */

function usage()
{
	print ("prune.php time mbox\n\n");
	print ("time    Delete mails older than /time/ days.\n");
	print ("mbox    Filename of the mbox file to prune.\n");
	die();
}
if ($argc != 3)
	usage();

if (!is_numeric($argv[1]))
	die("parameter 1 is not a number: ".$argv[1]."\n");
if (!is_writable($argv[2]))
	die("parameter 2 is not writable: ".$argv[2]."\n");

$time = $argv[1]*24*3600;
$mbox = $argv[2];


function fast_file($file)
{
	$lines = array();
	$fd = fopen ($file, "r");
	if ($fd === FALSE)
		return false;
	while (!feof ($fd)) 
	{
		$buffer = fgets($fd, 4096);
		$lines[] = $buffer;
	}
	fclose ($fd);
	return $lines;
}

function get_date($line)
{
	$msg_date = explode(' ', $line);
	array_shift($msg_date);
	array_shift($msg_date);

	$msg_date = implode(' ', $msg_date);
	return strtotime($msg_date);
}

$tmpfile	= tmpfile() or die ("could not create temporary file\n");
$delete		= date('U') - $time;
$lines		= fast_file($mbox) or die("could not read mbox\n");

for (	$i=0,$count=0,$count2=0,$line=$lines[0],$forcesave=false,$msg_date=0;
		array_key_exists($i, $lines);
		$i++)
{
	$line		= $lines[$i];

	// new message begins
	if (preg_match('/^From /', $line)) {

		$count ++;
		if ($count > 1) {
			// we have now a full message
			if ($msg_date > $delete || $forcesave) {
				$count2 ++;
				$forcesave = false;
				foreach ($msg as $l)
					if (fwrite($tmpfile, $l) === FALSE)
						die("could not write to temporary file\n");
			}

			// initialize a new message
			$msg = array();
		}
		$msg_date = get_date($line);
	}
	if (preg_match("/^Subject: DON'T DELETE THIS MESSAGE -- FOLDER INTERNAL DATA/", $line))
	{
		$forcesave = true;
		#print ("debug: forcing save for msg number $count (internal data)\n");
	}

	$msg[]	= $line;
		
}
// handle the last found message
if ($msg_date > $delete || $forcesave) {
	$count2 ++;
	foreach ($msg as $l)
		if (fwrite($tmpfile, $l) === FALSE)
			die("could not write to temporary file (last msg)\n");
}

// check for changes
if ($count != $count2) {
	// seek to the end of the temporary file
	fseek($tmpfile, 0);
	$fd = fopen ($mbox, "w") or die("could not open the mbox for writing\n");
	// and write temporary content to mbox
	while (false !== ($char = fgetc($tmpfile))) {
		fwrite($fd, $char) or die("could not write to mbox\n");
	}
	fclose($fd);
} else {
	#print ("debug: no change in mbox, not overwriting mailbox\n");
}

print ("Found $count messages and $count2 saved.\n");

fclose($tmpfile);

?>
