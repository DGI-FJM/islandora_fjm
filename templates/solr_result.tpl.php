<?php
dsm($item);
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
?>
<div class="atm_solr_result">
<!--<p><? print $item['type'] ?></p>-->
<?
switch($item['type']):
case "Performance":?>
	<h3><? t('Title:') ?>
	<p><? print $item['title'] ?></p>
	<p><? print $item['asdf'] ?></p>
<?	break;
case "Performer":?>
	<p><? print $item['name'] ?></p>
	<p><? print $item['piece'] ?></p>
	<p><? print $item['concert'] ?></p>
	<p><? print $item['cycle'] ?></p>
<?	break;
case "Program":?>
	<p><? print $item['concert'] ?></p>
	<p><? print $item['cycle'] ?></p>
<?	break;
case "Concert":?>
	<p><? print l($item['title'], 'fedora/repository/' . $item['PID']) ?></p>
<?	break;
case "Composer":
	print l('<img src="'. $item['icon'] . '"></img>' . $item['name'], 
		"fedora/repository/" . $item['PID'], 
		array(
			'html' => true
		)
	);
	break;
case "Score":?>
	<h2><? print t("Piece:") ?></h2>
	<h3><? print t('Title:') ?></h3>
	<p><? print $item['title']; ?></p>
	<h3><? print t("Composer:") ?></h3>
	<p><? print $item['composer'] ?></p>
	<h3><? print t("Score:") ?></h3>
	<p><?
	if($item['pdf'])
	{
		print l(t("PDF"), 'fedora/repository/' . $item['PID']);
	}
	else
	{
		print t("No PDF");
	}?></p>
	<p><?
	if($item['titn'] > 0)
	{
		print l(t('Available in library'), $titn_addr . $item['titn']);
	}
	else
	{
		print t('Not in library!');
	}
	?></p>
<?	break;
default:?>
	<p>Display not implemented for this type!</p>
<?endswitch;?>
</div>

