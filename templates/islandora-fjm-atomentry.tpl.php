<?php ?>
  <entry>
    <id><?php echo $id; ?></id>
    <title><?php echo $title; ?></title>
<?php if (!empty($published)): ?>
    <published><?php echo $published; ?></published>
<?php endif;
if (!empty($updated)): ?>
    <updated><?php echo $updated; ?></updated>
<?php endif; 
if (!empty($link)):?>
    <link href="<?php echo $link; ?>"/>
<?php endif;
if (!empty($content)): ?>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml"><?php echo $content; ?></div>
    </content>
<?php endif;
  foreach ($authors as $author):?>
    <author>
      <name><?php echo $author; ?></name>
    </author>
<?php endforeach; 
  foreach ($contributors as $contributor):?>
    <contributor>
      <name><?php echo $contributor; ?></name>
    </contributor>
<?php endforeach;?>
  </entry>
