<?php 
 drupal_add_css(drupal_get_path('module', 'islandora_fjm') . "/css/islandora_fjm_imagegallery.css", 'module')?>
<div <?php 
//FIXME:  Should this be moved to preprocess? I think so...  Probably...  Anyway.
$attributeStringArray = array();
foreach ($attributes as $attribute => $value) {
    if(is_array($value))
        $toOutput = implode(' ', $value);
    else
        $toOutput = $value;
    
    $attributeStringArray[] = $attribute ."=\"$toOutput\"";
}
echo implode(' ', $attributeStringArray);
?>>
<?php
$first = true;
foreach ($images as $image): 
    if($first):
        $first = false;?>
  <div class="islandora_fjm_photo">
      <a href="<?php echo $image['path']?>" rel="lightbox" id="image_strip_link" title="<?php echo $image['alt'] ?>">
          <img id="image_strip_big" src="<?php echo $image['path']?>" title="<?php echo $image['alt']?>"></img>
      </a>
  </div>
  <div class="islandora_fjm_jcarousel">

      <ul class="image_strip">
  <?php  endif;
      if(sizeof($images) > 1):?>
          <li>
              <img src="<?php echo $image['thumbnail']?>" title="<?php echo $image['alt']?>" path="<?php echo $image['path']?>"></img>
          </li>
  <?php  endif;
      endforeach; ?>
      </ul>
  <?php if(sizeof($images) > 1):?>
      <script type="text/javascript">
          //FIXME (minor): Might be a good idea to get this JS out of here? 
          //  (into another file, that is...)
          $("ul.image_strip > li > img").click(function () {
              $("#image_strip_big").attr("src", $(this).attr("path"));
              $("#image_strip_big").attr("title", $(this).attr("title"));
              $("#image_strip_link").attr("title", $(this).attr("title"));
              $("#image_strip_link").attr("href", $(this).attr("path"));
          });
      </script>
      <?php jcarousel_add("image_strip", 
              array(
                  'start' =>  "1", 
                  'wrap' => "both", 
                  'visible' => 3, 
                  'vertical' => FALSE, 
                  'itemFallbackDimension' => 300
              )
          );
      endif;
      lightbox2_add_files(); ?>
  </div>
</div>
