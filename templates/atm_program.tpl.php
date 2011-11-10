<?php 
/**
 * @param array<string> $concert Associative array of strings pertaining to the concert
 * @param string $pid The pid of the program.
 */
drupal_set_title(t('Programs'));
?>
<div class="islandora_fjm_program">
  <h2><? echo $concert['title'] . " - (" . $concert['year'] . ")" ?></h2>
  
  <? 
  echo theme('islandora_fjm_flexpaper', $pid);?>
  <h3><? echo $concert['cycle']?></h3><?
  
  if(!empty($toc)):?>
  <h4><? echo t('Table of contents')?></h4>
  <p><? echo $toc ?></p>
  <? endif;
  if(sizeof($notes) > 0):?>
  <h4><? echo t('Notes') ?></h4>
  <? foreach($notes as $note): ?>
  <p><? echo $note ?></p>
  <? endforeach; 
  endif;?>
  <div class="pdf">
  <? echo l('Download PDF', "fedora/repository/$pid/PDF/download/" . t("Program for !title.pdf", array('!title' => $concert['title'])));?>
  </div>
</div>
