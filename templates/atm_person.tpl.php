<?php 
/**
 * Template for a person/composer
 */
dsm($pid);
print theme('islandora_fjm_atm_imagegallery', $pid);
?>
<h2><? echo $name['first'] . " " . $name['last'] ?></h2>
<h3>
    <? echo ((!empty($date['birth']) && $date['birth'] !== FALSE) ? ($date['birth']) : t('unknown'))
        . ' - ' . ((!empty($date['death']) && $date['death'] !== FALSE) ? ($date['death']) : t('present/unknown')); ?>
</h3>
<div class="fjm_person_bio">
    <? echo $biography ?>
</div>
<h3><? echo t("Performances played or composed") ?></h3>
<? 
print theme('table', $performance_headers, $performances['associated']);
?>