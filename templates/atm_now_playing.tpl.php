<h2 class='player-content'><?php echo $piece ?></h2><br/><?php 
if (count($players) > 0): 
  ?><p class='player-content'><?php 
  foreach($players as $name => $instruments):
    $built[] = "$name: (" . implode(', ', $instruments) . ")";
  endforeach; 
  echo implode(', ', $built);
?></p><?php
endif;?>
