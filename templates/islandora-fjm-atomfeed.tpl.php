<?php echo <<<XML_START
<?xml version="1.0" encoding="utf-8"?>
XML_START;
?>

<feed xmlns="http://www.w3.org/2005/Atom">
  <id><?php echo $id; ?></id>
  <updated><?php echo $updated; ?></updated>
<?php if(!empty($link)): ?>
  <link href="<?php echo $link; ?>" rel="self"/>
<?php endif; ?>
  <title><?php echo $title; ?></title>
<?php if (!empty($subtitle)):?>
  <subtitle><?php echo $subtitle; ?></subtitle>
<?php endif; 
foreach ($entries as $entry) {
  echo $entry;
}?>
</feed>
<?php 
if (!headers_sent()) {
  header('Content-Type: application/atom+xml; charset=UTF-8');
}
exit(); ?>
