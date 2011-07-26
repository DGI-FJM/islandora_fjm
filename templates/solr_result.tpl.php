<?php
if(is_callable('dsm'))
    dsm($item);
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
$item_path = 'fedora/repository/' . $item['PID'];
?>
<div class="atm_solr_result">
<!--<p><? print $item['type'] ?></p>-->
<?
switch($item['type']):
case "Concert":?>
    <div class="concert_top_left">
        <? print l(theme('image', 'fedora/repository/' . $item['icon'] . '/TN', '', '' ,'', false), 
                'fedora/repository/' . $item['PID'], 
                array('html' => true)) ?>
    </div>
    <div class="concert_top_center">
        <h3><? print l($item['title'], $item_path) ?></h3>
        <p><? print $item['cycle'] ?></p>
    </div>
    <div class="concert_top_right">
        <div class="item_stat">
            <h4><? print t("Program:") ?></h4>
            <p><? print ($item['program']['pdf'])?(t("Available as PDF")):(t("No PDF")) ?></p>
            <p><? print ($item['program']['titn'] > 0)?(t("Available in Library")):(t("Not in Library")) ?></p>
        </div>
        <div class="item_stat">
            <h4><? print t("Audio:") ?></h4>
            <p><? print ($item['audio'])?('asdf'):('fdsa') ?></p>
        </div>
    </div>
    <div class="concert_bottom">
        <? print 'put stuff here' ?>
    </div>
        
<?	break;
default:?>
	<p>Non-table display not implemented for this type!</p>
<?endswitch;?>
</div>

