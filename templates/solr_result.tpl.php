<?php
dsm($item);
?>
<div class="atm_solr_result">
<!--<p><? print $item['type'] ?></p>-->
<?
switch($item['type']):
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
default:?>
	<p>Display not implemented for this type!</p>
<?endswitch;?>
</div>

