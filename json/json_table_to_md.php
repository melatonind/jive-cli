#!/usr/bin/php -f
<?php

$headings = array(
	"name" 			=> "Account Name",
	"email" 		=> "EMail",
	"id"			=> "Account ID",
	"alias"			=> "Account alias",
	"custodian" 		=> "Custodian",
	"direct_connect"	=> "Direct Connect",
	"cidr_range" 		=> "CIDR Range",
	"platform"		=> "Platform Image",
	"shared"		=> "Shared or LoB",
	"fedorated"		=> "Federated Identity",
	"mfa"			=> "root MFA",
	"cloudtrail"		=> "CloudTrail",
	"awsconfig"		=> "AWS Config",
	"cloudability"		=> "Cloudability",
);

$o = array();

$a = "|";
$b = "|";

foreach($headings as $index => $heading)
{
	$a.= $heading."|";
	$b.= str_repeat("-", strlen($heading))."|";
}
$o[] = $a;
$o[] = $b;
$filename = $_SERVER['argv'][1];
$file = file_get_contents($filename, true);
$json = json_decode($file);
foreach($json as $id => $account)
{
	$account->id = $id;
	$line = "|";
	foreach($headings as $index => $heading)
	{
		if(isset($account->$index))
		{
			$line.= $account->$index;
		}
		$line.= "|";
	}
	$o[] = $line;
}

foreach($o as $line)
{
	echo "$line\n";
}
?>
