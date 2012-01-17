<?php 
/**
 * @param array<string> $concert Associative array of strings pertaining to the concert
 * @param string $pid The pid of the program.
 */
drupal_set_title(t('Programs'));
?>
<div class="islandora_fjm_program">
  <h2><?php echo $concert['title'] . " - (" . $concert['year'] . ")" ?></h2>
  
  <?php 
  echo theme('islandora_fjm_flexpaper', $pid);?>
  <h3><?php echo $concert['cycle']?></h3><?
  
  if(!empty($toc)):?>
  <h4><?php echo t('Table of contents')?></h4>
  <p><?php echo $toc ?></p>
  <?php endif;
  if(sizeof($notes) > 0):?>
  <h4><?php echo t('Notes') ?></h4>
  <?php foreach($notes as $note): ?>
  <p><?php echo $note ?></p>
  <?php endforeach; 
  endif;?>
  <div class="pdf">
  <?php echo l('Download PDF', "fedora/repository/$pid/PDF/download/" . t("Program for !title.pdf", array('!title' => $concert['title'])));?>
  </div>
</div>
