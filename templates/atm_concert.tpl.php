<?php 
drupal_add_css("$islandoraPath/css/islandora_fjm_concert.css");
drupal_set_title(t('Concerts'));
//dsm($concert);
?>
<div class="islandora_fjm_concert">
  
  <div class="atm_concert_top">
      <? echo theme('islandora_fjm_atm_imagegallery', $pid) ?>
      <div class="atm_concert_top_right">
        <div class="islandora_fjm_description">
          <h3 class="atm_concert_cycle"><? echo $concert['cycle'] ?></h3>
          <p class="atm_concert_date"><? echo format_date($concert['date']->format('U'), 'custom', 'd/m/Y') ?></p>
          <p class="atm_concert_description"><? echo $concert['description'] ?></p>
        </div>
        <div id="flowplayer">
        <? 
        //TODO:  Need to (better) determine whether or not to show the player...  Or just always show it?
        if (sizeof($concert['performance_rows']) + sizeof($concert['lecture_rows']) > 0)
        {
            echo FJM::addPlayer('div.atm_track');
            //echo theme('islandora_fjm_atm_flowplayer', 'div.atm_track');
            drupal_add_css("$islandoraPath/css/islandora_fjm_playlist.css");
        }
        ?>
        </div>
     </div><!--atm_con_top_right -->
     <div class="clearfix"></div>
  </div>
  <div class="atm_concert_mid">
    <h3><? echo t('Program PDF:')?></h3>
    <p>
     <? 
       if ($concert['program']['pid']) { 
         echo l(t('Available'), 'fedora/repository/' . $concert['program']['pid'], array('attributes' => array('class' => 'pdf')));
       }
       else {
         echo t('N/A');
       }
     ?>
    </p>
  </div> <!-- atm_con_mid -->
  <div class="atm_concert_bottom">
    <div class="atm_concert_bottom_left">
      <!-- What's supposed to go here again? -->
    </div>
    <div class="atm_concert_bottom_right">
      <?
        if (sizeof($concert['performance_rows']) > 0) {
            echo theme('table', $concert['headers']['performance'], $concert['performance_rows'], array('class' => 'atm_concert_performance_table'), t('Works'));
        }
        if (sizeof($concert['lecture_rows']) > 0) {
            echo theme('table', $concert['headers']['lecture'], $concert['lecture_rows'], array('class' => 'atm_concert_lecture_table'), t('Conferences'));
        }
      ?>
    </div><!--bottom right-->
    <div class="clearfix"></div>
  </div>
  <? if ($pagenumber != NULL && $pagenumber > 0) : ?>
  <script type="text/javascript">
      $(function() {$(".concertOrder_<? echo $pagenumber ?>:first > a").click()});
  </script>
  <?endif;?>
</div>
