<?php 
drupal_add_css("$islandoraPath/css/islandora_fjm_concert.css");
drupal_set_title(t('Concerts'));
//dsm($concert);
?>
<div class="islandora_fjm_concert">
  <h2><? echo $concert['title']; ?></h2>
  <div class="atm_concert_top">
    <div class="leftcolumn">
      <div class="block">
      <? echo theme('islandora_fjm_atm_imagegallery', $pid) ?>
      </div>
    </div>
    <div class="rightcolumn">
      <div class="block">
        <div class="islandora_fjm_description">
          <h3 class="atm_concert_cycle"><? echo $concert['cycle'] ?></h3>
          <p class="atm_concert_date"><? echo format_date($concert['date']->format('U'), 'custom', 'd/m/Y') ?></p>
          <p class="atm_concert_description"><? echo $concert['description'] ?></p>
        </div>
      </div>
   </div><!--atm_con_top_right -->
   <div class="clearfix"></div>
  </div>
  <div class="atm_concert_mid">
    <div class="leftcolumn">
      <div class="block">
      <h3><? 
         if ($concert['program']['pid']) { 
           echo l(t('Program PDF Available'), 'fedora/repository/' . $concert['program']['pid'], array('attributes' => array('class' => 'pdf')));
         }
         else {
           echo t('N/A');
         }
       ?></h3>
      </div>
    </div>
    <div id="flowplayer" class="rightcolumn">
      <div class="block">
      <? 
      //TODO:  Need to (better) determine whether or not to show the player...  Or just always show it?
      if (sizeof($concert['performance_rows']) + sizeof($concert['lecture_rows']) > 0)
      {
          //echo FJM::addPlayer('div.atm_track');
          echo theme('islandora_fjm_atm_flowplayer');
          //drupal_add_css("$islandoraPath/css/islandora_fjm_playlist.css");
      }
      ?>
      </div>
    </div>
  </div> <!-- atm_con_mid -->
  <div class="atm_concert_bottom">
    <div class="leftcolumn">
      <div class="block">
        <h3><? echo t('Voice archive'); ?></h3>
        <? 
          if (sizeof($concert['lecture_rows']) > 0) {
            echo theme('table', $concert['headers']['lecture'], $concert['lecture_rows'], array('class' => 'atm_concert_lecture_table'));
          }
          else {
            echo theme('table', array(), array(array(t('No items'))), array('class' => 'atm_concert_lecture_table'));
          }
        ?>
      </div>
    </div>
    <div class="rightcolumn">
      <div class="block">
        <h3><? echo t('Works'); ?></h3>
        <?
          if (sizeof($concert['performance_rows']) > 0) {
            echo theme('table', $concert['headers']['performance'], $concert['performance_rows'], array('class' => 'atm_concert_performance_table'));
          }
          else {
            echo theme('table', array(), array(array(t('No items'))), array('class' => 'atm_concert_performance_table'));
          }
        ?>
      </div>
    </div><!--bottom right-->
    <div class="clearfix"></div>
  </div>
  <? if ($pagenumber != NULL && $pagenumber > 0) : ?>
  <script type="text/javascript">
      $(function() {$(".concertOrder_<? echo $pagenumber ?>:first > a").click()});
  </script>
  <?endif;?>
</div>
