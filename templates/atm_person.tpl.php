<?php 
/**
 * Template for a person/composer
 */
?>
<div class='leftcolumn'>
<?
echo theme('islandora_fjm_atm_imagegallery', $pid);
echo theme('table', $performance_headers, $performances['associated']);
?>
</div>
<div class='rightcolumn'>
<h2><? echo $name['first'] . " " . $name['last'] ?></h2>
<h3>
    <? echo ((!empty($date['birth']) && $date['birth'] !== FALSE) ? ($date['birth']) : t('unknown'))
        . ' - ' . ((!empty($date['death']) && $date['death'] !== FALSE) ? ($date['death']) : ''); ?>
</h3>
<div class="fjm_person_bio">
    <? echo $biography ?>
</div>
<h3><? echo t("Performances in CLAMOR") ?></h3>
</div>
