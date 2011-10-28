<?php  
global $base_url;
$hostname = $base_url;
$mod_base = drupal_get_path('module', 'islandora_fjm');

//FIXME: This should probably be moved elsewhere...  As well as the later inline JS...
drupal_add_js("$base/flowplayer-3.2.6.min.js");
drupal_add_js("$base/flowplayer.playlist-3.0.8.js"); 
drupal_add_css($mod_base . '/css/islandora_fjm_player.css', 'module'); ?>

<div class="player" id="atm_player"><!-- placeholder --></div>
<ol class="atm_clips" style="display: none;"></ol>
<script type="text/javascript">
  <? if(!empty($trackingCode)): ?>
  function update_ga(event, url, time) {
    if (typeof _gat != "undefined") {
        //object exists ... execute code here.
        var _tracker = _gat._getTracker('<? echo $trackingCode; ?>');
    }

    if (typeof _tracker != 'undefined') {
      if (time != null) {
        _tracker._trackEvent('Audio', event, url, time);
      }
      else {
        _tracker._trackEvent('Audio', event, url);
      }
    }
  }
  <? endif; ?>
  
  $(function() {
    $f("atm_player", "/<? echo $base; ?>/flowplayer-3.2.7.swf", {
      plugins: {
        controls: {
          all: false,
          play: true,
          playlist: true,
          autoHide: false,
          scrubber: true,
          time: true,
          height: 30
        },
        audio: {
          url: "/<? echo $base; ?>/flowplayer.audio-3.2.2.swf"
        },
        content: {
          url: "/<? echo $base; ?>/flowplayer.content-3.2.0.swf",
          stylesheet: "/<? echo $mod_base ;?>/css/islandora_fjm_player.css",
          width: '95%',
          height: '60%'
        }
      },
      clip: {
        baseUrl: "<? echo $base_url; ?>",
        autoPlay: true,
        autoBuffering: true,
        <? if (!empty($trackingCode)): ?>
        onStop: function(clip) {
          update_ga('Stop', clip.url, parseInt(this.getTime()));
        },
        onPause: function(clip) {
          update_ga('Pause', clip.url, parseInt(this.getTime()));
        },
        onFinish: function(clip) {
          update_ga('Finish', clip.url, null);
        }
        <? endif; ?>
      },
      onPlaylistReplace: function(){ 
        $("<? echo $selector; ?>").show(); 
      } 
    });

    $f("atm_player").playlist("<? echo $selector; ?>", {
      loop: true,
      template: "<li><a href=\"${url}\">${title} - ${subTitle}</a></li>",
      manual: false
    });
   });
  
  Drupal.settings.islandora_fjm.play = function (piece_index) {
    var piece = Drupal.settings.islandora_fjm.piece[piece_index];
    $f().play(piece.playlist);
    $f().onStart(function(clip) {
      $f().getPlugin('content').setHtml(piece.now_playing);
      <? if (!empty($trackingCode)): ?>
      update_ga('Play', clip.url, null);
      <? endif; ?>
    });
  };
</script>