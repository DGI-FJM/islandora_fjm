<?php  
global $base_url;
$hostname = $base_url; 

//FIXME: This should probably be moved elsewhere...
drupal_add_js("$base/flowplayer-3.2.6.min.js");
drupal_add_js("$base/flowplayer.playlist-3.0.8.js"); 
drupal_add_css(drupal_get_path('module', 'islandora_fjm') . '/css/islandora_fjm_player.css', 'module'); ?>

<div class="player" id="atm_player"><!-- placeholder --></div>
<ol class="atm_clips" style="display: none;"></ol>
<script type="text/javascript">
    $(function() {
        $f("atm_player", "/<? echo $base; ?>/flowplayer-3.2.7.swf", {
            plugins: {
                controls: {
                    all: false,
                    //Play button here is a Bad Idea (also happens to avoid a bug:
                    //  When the player\' play button was clicked first, 
                    //  the CSS was not being changed, and as such the icons 
                    //  for tracks were not changing; however, if the track icon was
                    //  clicked first, then the button in the player would
                    //  work to change the CSS)
                    play: true,
                    autoHide: false,
                    scrubber: true,
                    time: true,
                    height: 30
                },
                audio: {
                    url: "/<? echo $base; ?>/flowplayer.audio-3.2.2.swf"
                }
            },
            clip: {
                baseUrl: "<? echo $base_url; ?>",
                autoPlay: true,
                autoBuffering: true
            }
        });
        
        $f("atm_player").playlist("<? echo $selector; ?>", {
            loop: true,
            template: "<li><a href=\"${url}\">${title} - ${subTitle}</a></li>",
            manual: false
        });
    });
</script>