<?php 
 drupal_add_css($path, $type)?>
<div <? 
//FIXME:  Should this be moved to preprocess? I think so...  Anyway.
$attributeStringArray = array();
foreach ($attributes as $attribute => $value) {
    if(is_array($value))
        $toOutput = implode(' ', $value);
    else
        $toOutput = $value;
    
    $attributeStringArray[] = $attribute ."=\"$toOutput\" ";
}

echo implode(' ', $attributeStringArray);
?>>
<?
$first = true;
foreach ($images as $image): 
    if($first):
        $first = false;?>
    <a href="<? echo $image['path']?>" rel="lightbox" id="image_strip_link">
        <img id="image_strip_big" src="<? echo $image['path']?>" alt="<? $image['alt']?>"></img>
    </a>
    
    <ul class="image_strip">
<?  endif;
    if(sizeof($images) > 1):?>
        <li>
            <img src="<? echo $image['thumbnail']?>" alt="<? echo $image['alt']?>" path="<? echo $image['path']?>"></img>
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
            $("#image_strip_big").attr("alt", $(this).attr("alt"));
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
