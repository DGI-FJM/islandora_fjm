<?php 
    /**
     * @param string $title The title of the piece
     * @param string $composer The composer of the piece
     * @param string $abstract Short description (taken from MODS?)
     * @param array<string> $notes An array of notes (taken from MODS?)
     */
drupal_set_title(t('Scores'));
?>
<div class="islandora_fjm_score">
  <h2><? echo $title ?></h2>
  <h3><? echo $composer ?></h3>
  <? echo theme('islandora_fjm_flexpaper', $pid) ?>
  <div class="islandora_fjm_download">
      <? echo l(t('Download PDF'), "fedora/repository/$pid/PDF/download/" . t("Score") . " - $title.pdf") ?>
  </div>
  <div class="islandora_fjm_description">
  <? if(!empty($abstract)): ?>
      <h4><? echo t("Abstract") ?></h4>
      <p><? echo $abstract ?></p>
  <? endif; ?>
  <? 
  if(sizeof($notes) > 0): ?>
      <h4><? echo t("Notes") ?></h4>
  <?foreach($notes as $note): ?>
      <p><? echo $note ?></p>
  <? 
  endforeach; 
  endif;
  ?>
  </div>
</div>
