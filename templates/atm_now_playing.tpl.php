<h2 class='player-content'><? echo $piece ?></h2><br/><? 
if (count($players) > 0): 
  ?><p class='player-content'><? 
  foreach($players as $name => $instruments):
    $built[] = "$name: (" . implode(', ', $instruments) . ")";
  endforeach; 
  echo implode(', ', $built);
?></p><?
endif;?>
