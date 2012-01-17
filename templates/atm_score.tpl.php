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
  <h2><?php echo $title ?></h2>
  <h3><?php echo $composer ?></h3>
  <?php echo theme('islandora_fjm_flexpaper', $pid) ?>
  <div class="islandora_fjm_description">
  <?php if(!empty($abstract)): ?>
      <h4><?php echo t("Abstract") ?></h4>
      <p><?php echo $abstract ?></p>
  <?php endif; ?>
  <?php 
  if(sizeof($notes) > 0): ?>
      <h4><?php echo t("Notes") ?></h4>
  <?php foreach($notes as $note): ?>
      <p><?php echo $note ?></p>
  <?php 
  endforeach; 
  endif;
  ?>
  </div>
  <div class="pdf">
      <?php echo l(t('Download PDF'), "fedora/repository/$pid/PDF/download/" . t("Score for !title.pdf", array('!title' => $title))) ?>
  </div>
</div>
