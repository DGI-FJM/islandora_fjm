<?php
dsm($item);
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
?>
<div class="atm_solr_result">
<!--<p><? print $item['type'] ?></p>-->
<?
switch($item['type']):
case "Concert":?>
	<p><? print l($item['title'], 'fedora/repository/' . $item['PID']) ?></p>
<?	break;
default:?>
	<p>Non-table display not implemented for this type!</p>
<?endswitch;?>
</div>

