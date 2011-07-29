<?php 
/**
 * @param array<string> $concert Associative array of strings pertaining to the concert
 * @param string $pid The pid of the program.
 */
?>
<h2><? echo $concert['title'] ?></h2>
<h3><? echo $concert['cycle']?></h3>
<? echo theme('islandora_fjm_flexpaper', $pid) ?>