<?php 
/**
 * Template for a person/composer
 */
?>
<div class='leftcolumn'>
<?
echo theme('islandora_fjm_atm_imagegallery', $pid);
?><div class='performance_table'>
<h3><? echo t("Performances in CLAMOR") ?></h3><?
echo theme('table', $performance_headers, $performances['associated']);
?></div>
</div>
<div class='rightcolumn'>
<? drupal_set_title(t('!first !last (!birth - !death)', array(
    '!first' => $name['first'],
    '!last' => $name['last'],
    '!birth' => ((!empty($date['birth']) && $date['birth'] !== FALSE) ? ($date['birth']) : t('unknown')),
    '!death' => ((!empty($date['death']) && $date['death'] !== FALSE) ? ($date['death']) : ''))));?>
<div class="fjm_person_bio">
    <? echo $biography ?>
</div>

</div>
