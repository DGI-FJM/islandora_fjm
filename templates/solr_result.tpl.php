<?php
if(is_callable('dsm')) {
    //dsm($item);
}
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
$item_path = 'fedora/repository/' . $item['PID'];
?>
<div class="atm_solr_result">
<?
switch($item['type']):
case "Concert":
case "Conciertos":?>
    <div class="concert_top_left">
        <? print l(theme('image', 'fedora/repository/' . $item['icon'] . '/TN', '', '' ,'', false), 
                'fedora/repository/' . $item['PID'], 
                array('html' => true)) ?>
    </div>
    <div class="concert_top_center">
        <h3><? print l($item['title'], $item_path) ?></h3>
        <p><? print $item['cycle'] ?></p>
        <p><? print format_date($item['date']->format('U'), 'custom', 'd/m/Y') ?></p>
    </div>
    <div class="concert_top_right">
        <h4><? echo t('Available files:') ?></h4>
        <ul>
        <? if (is_null($item['digital_objects'])) { ?>
            <li><? echo t('None')?></li>
        <? }
            else foreach ($item['digital_objects'] as $do) {?>
            <li><? echo $do ?></li>
        <?  } ?>
        </ul>
    </div>
    <div class="concert_bottom">
        <? 
        foreach ($item['accordion'] as $type => $values):
            if ($values != NULL && sizeof($values) > 0): ?>
                <h3><a href="#"><? echo $type ?></a></h3>
                <ul>
                <? sort($values); 
                foreach ($values as $val): ?>
                    <li><? echo $val ?></li>
                <? endforeach; ?>
                </ul>
            <?endif;
        endforeach;?>
    </div>
        
<?	break;
default:?>
	<p>Non-table display not implemented for this type!</p>
<?endswitch;?>
</div>

