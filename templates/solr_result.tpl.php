<?php
if(is_callable('dsm'))
    dsm($item);
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
?>
<div class="atm_solr_result">
<!--<p><? print $item['type'] ?></p>-->
<?
switch($item['type']):
case "Concert":?>
    <a href="<? print url('fedora/repository/' . $item['PID']) ?>">
        <div class="concert_top_left">
            <h3><? print $item['title'] ?></h3>
            <p><? print $item['cycle'] ?></p>
        </div>
        <div class="concert_top_right">
            <? print theme('image', 'fedora/repository/' . $item['icon'] . '/TN', '', '' ,'', false) ?>
            <div class="item_stat program_status <? print ($item['program']['pdf'] || $item['program']['titn'] > 0)?("has_program"):("no_program") ?>">
                <? print ($item['program']['pdf'] || $item['program']['titn'] > 0)?("has_program"):("no_program") ?>
            </div>
            <div class="item_stat lecture_status <? print 'asdf' ?>">
            
            </div>
        </div>
        <div class="concert_bottom">
            <? print 'put stuff here' ?>
        </div>
    </a>
        
<?	break;
default:?>
	<p>Non-table display not implemented for this type!</p>
<?endswitch;?>
</div>

