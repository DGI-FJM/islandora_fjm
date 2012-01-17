<?php
if(is_callable('dsm')) {
    //dsm($item);
}
$titn_addr = 'http://www.march.es/abnopac/abnetcl.exe?ACC=DOSEARCH&xsqf01=';
$item_path = 'fedora/repository/' . $item['PID'];
?>
<div class="atm_solr_result">
<?php
switch($item['type']):
case "Concert":
case "Conciertos":?>
    <div class="concert_top_left">
        <?php print l(theme('image', 'fedora/repository/'. $item['icon'] .'/TN', '', '' ,'', false), 
                'fedora/repository/' . $item['PID'], 
                array('html' => true)) ?>
    </div>
    <div class="concert_top_center">
        <h3><?php print l($item['title'], $item_path) ?></h3>
        <p><?php print $item['cycle'] ?></p>
        <p><?php print format_date($item['date']->format('U'), 'custom', 'd/m/Y') ?></p>
    </div>
    <div class="concert_top_right">
        <h4><?php echo t('Available files:') ?></h4>
        <ul>
        <?php if (is_null($item['digital_objects'])) { ?>
            <li><?php echo t('None')?></li>
        <?php }
            else foreach ($item['digital_objects'] as $do) {?>
            <li><?php echo $do ?></li>
        <?php  } ?>
        </ul>
    </div>
    <div class="concert_bottom">
        <?php 
        foreach ($item['accordion'] as $type => $values):
            if ($values != NULL && sizeof($values) > 0): ?>
                <h3><a href="#"><?php echo $type ?></a></h3>
                <ul>
                <?php sort($values); 
                foreach ($values as $val): ?>
                    <li><?php echo $val ?></li>
                <?php endforeach; ?>
                </ul>
            <?php endif;
        endforeach;?>
    </div>
        
<?php	break;
default:?>
	<p>Non-table display not implemented for this type!</p>
<?php endswitch;?>
</div>

