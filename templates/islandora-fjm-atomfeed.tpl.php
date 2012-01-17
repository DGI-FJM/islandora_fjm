<?php ?>
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<feed xmlns="http://www.w3.org/2005/Atom">
  <id><?php echo $id; ?></id>
  <link href="<?php ?>" rel="self"/>
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
