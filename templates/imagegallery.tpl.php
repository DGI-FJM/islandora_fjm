<?php 
 drupal_add_css(drupal_get_path('module', 'islandora_fjm') . "/css/islandora_fjm_imagegallery.css", 'module')?>
<div <? 
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
<?
$first = true;
foreach ($images as $image): 
    if($first):
        $first = false;?>
  <div class="islandora_fjm_photo">
      <a href="<? echo $image['path']?>" rel="lightbox" id="image_strip_link" title="<? echo $image['alt'] ?>">
          <img id="image_strip_big" src="<? echo $image['path']?>" title="<? echo $image['alt']?>"></img>
      </a>
  </div>
  <div class="islandora_fjm_jcarousel">

      <ul class="image_strip">
  <?  endif;
      if(sizeof($images) > 1):?>
          <li>
              <img src="<? echo $image['thumbnail']?>" title="<? echo $image['alt']?>" path="<? echo $image['path']?>"></img>
          </li>
  <?  endif;
      endforeach; ?>
      </ul>
  <? if(sizeof($images) > 1):?>
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
      <? jcarousel_add("image_strip", 
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