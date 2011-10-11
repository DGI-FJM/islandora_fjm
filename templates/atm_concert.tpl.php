<?php 
drupal_add_css("$islandoraPath/css/islandora_fjm_concert.css");

//dsm($concert);
?>
<h2 class="atm_concert_title"><? echo $concert['title'] ?></h2>
<div class="atm_concert_top">
    <? echo theme('islandora_fjm_atm_imagegallery', $pid) ?>
    <div class="atm_concert_top_right">
        <h3 class="atm_concert_cycle"><? echo $concert['cycle'] ?></h3>
        <p class="atm_concert_date"><? echo format_date($concert['date']->format('U'), 'custom', 'Y/m/d') ?></p>
        <p class="atm_concert_description"><? echo $concert['description'] ?></p>
   </div><!--atm_con_top_right -->
   <div class="atm_concert_top_right">
       <div style="float: left; padding: 15px;">
           <h3><? echo t('Program PDF:')?></h3>
           <p>
               <? 
                   if ($concert['program']['pid']) { 
                       echo l(t('Available'), 'fedora/repository/' . $concert['program']['pid']);
                   }
                   else {
                       echo t('N/A');
                   }
               ?>
           </p>
       </div>
   </div>
</div><!--atm_con_top -->
<div class="atm_concert_bottom">
    <div class="atm_concert_bottom_left">
        <?
            //TODO:  Need to (better) determine whether or not to show the player...  Or just always show it?
            if (sizeof($concert['performance_rows']) + sizeof($concert['lecture_rows']) > 0)
            {
                //echo FJM::addPlayer('div.atm_track');
                echo theme('islandora_fjm_atm_flowplayer', 'div.atm_track');
                drupal_add_css("$islandoraPath/css/islandora_fjm_playlist.css");
            }
            if (sizeof($concert['performance_rows']) > 0) {
                echo theme('table', $concert['headers']['performance'], $concert['performance_rows'], array('class' => 'atm_concert_performance_table'), t('Works'));
            }
            if (sizeof($concert['lecture_rows']) > 0) {
                echo theme('table', $concert['headers']['lecture'], $concert['lecture_rows'], array('class' => 'atm_concert_lecture_table'), t('Conferences'));
            }
        ?>
    </div><!--bottom left-->
</div>
<? if ($pagenumber != NULL && $pagenumber > 0) : ?>
<script type="text/javascript">
    $(function() {$(".concertOrder_<? echo $pagenumber ?>:first > a").click()});
</script>
<?endif;?>
