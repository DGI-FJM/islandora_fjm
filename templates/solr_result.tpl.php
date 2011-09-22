<?php
if(is_callable('dsm'))
    dsm($item);
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
$item_path = 'fedora/repository/' . $item['PID'];
?>
<div class="atm_solr_result">
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
        <h4><? echo t('Available objects:') ?></h4>
        <ul>
        <? if (is_null($item['digital_objects'])) { ?>
            <li><? echo t('None')?></li>
        <? }
            else foreach ($item['digital_objects'] as $do) {?>
            <li><? echo $do ?></li>
        <?  } ?>
        </ul>
        <!--<div class="item_stat">
            <h4><? print t("Program:") ?></h4>
            <p><? print ($item['program']['pdf'])?(t("Available as PDF")):(t("No PDF")) ?></p>
            <p><? print ($item['program']['titn'] > 0)?(t("Available in Library")):(t("Not in Library")) ?></p>
        </div>
        <div class="item_stat">
            <h4><? print t("Audio:") ?></h4>
            <p><? print (!empty($item['audio']))?('asdf'):('fdsa') ?></p>
        </div>-->
    </div>
    <div class="concert_bottom">
        <? if ($item['composers'] != NULL && sizeof($item['composers']) > 0): ?>
        <h3><a href="#"><? echo t('Composers') ?></a></h3>
        <ul>
        <?  foreach ($item['composers'] as $composer) :?>
            <li><? echo $composer ?></li>
        <? endforeach; ?>
        </ul>
        <?endif;
        if ($item['performers'] != NULL && sizeof($item['performers']) > 0): ?>
        <h3><a href="#"><? echo t('Performers') ?></a></h3>
        <ul>
        <?  foreach ($item['performers'] as $performer) :?>
            <li><? echo $performer ?></li>
        <? endforeach; ?>
        </ul>
        <?endif;?>
    </div>
        
<?	break;
default:?>
	<p>Non-table display not implemented for this type!</p>
<?endswitch;?>
</div>

