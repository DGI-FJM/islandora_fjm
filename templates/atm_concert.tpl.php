<?php 
drupal_add_css("$islandoraPath/css/islandora_fjm_concert.css");

dsm($concert);
?>
<h2 class="atm_concert_title"><? echo $concert['title'] ?></h2>
<h3 class="atm_concert_cycle"><? echo $concert['cycle'] ?></h3>
<div class="atm_concert_top">
    <? echo theme('islandora_fjm_atm_imagegallery', $pid) ?>
    <div class="atm_concert_top_right">
        <p class="atm_concert_date"><? echo $concert['date']->format("Y/m/d") ?></p>
        <p class="atm_concert_description"><? echo $concert['description'] ?></p>
   </div><!--atm_con_top_right -->
</div><!--atm_con_top -->
<div class="atm_concert_bottom">
    <div class="atm_concert_bottom_left">
        <?
            if (sizeof($concert['performance_rows']) > 0) {
                echo theme('table', $concert['headers']['performance'], $concert['performance_rows'], array('class' => 'atm_concert_performance_table'), t('Works'));
            }
            if (sizeof($concert['lecture_rows']) > 0) {
                echo theme('table', $concert['headers']['lecture'], $concert['lecture_rows'], array('class' => 'atm_concert_lecture_table'), t('Conferences'));
            }
            if (sizeof($concert['performance_rows']) + sizeof($concert['lecture_rows']) > 0)
            {
                echo FJM::addPlayer('div.atm_track');
                drupal_add_css("$islandoraPath/css/islandora_fjm_playlist.css");
            }
        ?>
    </div><!--bottom left-->
</div>