<?php 
/**
 * Template file to make a FlexPaper viewer.
 * @param string flexpaper_path
 * @param string swf_url
 */

$base = drupal_get_path("module", "islandora_fjm");
drupal_add_js("$base/flexpaper/js/flexpaper_flash.js");
drupal_add_css("$base/css/islandora_fjm_flexpaper.css");
?>
<div id="flexpaper">
    <div id="viewer"></div>
    <script type="text/javascript">
        var fp = new FlexPaperViewer(
            "<? echo $flexpaper_path; ?>/FlexPaperViewer",
            "viewer",
            {
                config : {
                    <? foreach($flexpaper_config as $key => $value): 
                        //NOTE:  IDE (NetBeans 7.0) says there's a parse error 
                        //  here in the javascript, but the code works! ?>
                        <? echo $key; ?> : <? echo $value; ?>,
                    <? endforeach; ?>
                }
            }
        );
    </script>
</div>
