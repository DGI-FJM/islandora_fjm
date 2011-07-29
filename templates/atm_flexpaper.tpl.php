<?php 
/**
 * Template file to make a FlexPaper viewer.
 * @param string flexpaper_path
 * @param string swf_url
 */

$base = drupal_get_path("module", "islandora_fjm") . '/flexpaper';
drupal_add_js("$base/js/flexpaper_flash.js");
?>
<div id="flexpaper">
    <a id="viewer" style="width: 700px; height: 400px; display: block;"></a>
    <script type="text/javascript">
        var fp = new FlexPaperViewer(
            "<? echo $flexpaper_path; ?>/FlexPaperViewer",
            "viewer",
            {
                config : {
                    <? foreach($flexpaper_config as $key => $value): 
                        //NOTE:  IDE says there's a parse error here in the JS, 
                        //  but the code works! ?>
                        <? echo $key; ?> : <? echo $value; ?>,
                    <? endforeach; ?>
                }
            }
        );
    </script>
</div>
