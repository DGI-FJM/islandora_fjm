<?php  
global $base_url;
$hostname = $base_url;
$mod_base = drupal_get_path('module', 'islandora_fjm');
$trackingCode = variable_get('googleanalytics_account', NULL);
//FIXME: This should probably be moved elsewhere...  As well as the later inline JS...
drupal_add_js("$base/flowplayer-3.2.6.min.js", 'module');
drupal_add_js("$base/flowplayer.playlist-3.0.8.js", 'module'); 
drupal_add_css($mod_base . '/css/islandora_fjm_player.css', 'module'); ?>

<div class="player" id="atm_player"></div>
<ol class="atm_clips" style="display: none;"></ol>
<script type="text/javascript">
  
  function update_ga(event, url, time) {
    <? if(!empty($trackingCode)): ?>
    if (typeof _gaq != "undefined") {
      if (time != null) {
        //_tracker._trackEvent('Audio', event, url, time);
        _gaq.push(['_trackEvent', 'Audio', event, url, time])
      }
      else {
        _gaq.push(['_trackEvent', 'Audio', event, url]);
      }
    }
    <? endif; ?>
  }

  
  $(function() {
    $f("atm_player", "/<? echo $base; ?>/flowplayer-3.2.7.swf", {
      plugins: {
        controls: {
          all: false,
          play: true,
          playlist: true,
          volume: true,
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
        autoPlay: false,
        autoBuffering: true,
        onStop: function(clip) {
          update_ga('Stop', clip.url, parseInt(this.getTime()));
        },
        onPause: function(clip) {
          update_ga('Pause', clip.url, parseInt(this.getTime()));
        },
        onFinish: function(clip) {
          update_ga('Finish', clip.url, null);
          if (clip.index + 1 == this.getPlaylist().length) {
            //Make it start the next playlist on the last piece...
            Drupal.settings.islandora_fjm.current_index += 1;
            if (Drupal.settings.islandora_fjm[Drupal.settings.islandora_fjm.current_type].length > Drupal.settings.islandora_fjm.current_index) {
              this.setPlaylist(Drupal.settings.islandora_fjm[Drupal.settings.islandora_fjm.current_type][Drupal.settings.islandora_fjm.current_index]).play(0);
            }
            else {
              this.stop();
            }
          }
          else {
            this.play(clip.index + 1);
          }
        },
        onStart: function(clip) {
          update_ga('Play', clip.url, null);
        },
        subTitle: ''
      },
      onPlaylistReplace: function(clips){ 
        $("<? echo $selector; ?>").show();
        //var index = Drupal.settings.islandora_fjm.current_index;
        if (clips.length > 0 && typeof clips[0].now_playing != 'undefined') {
          this.getPlugin('content').setHtml(clips[0].now_playing);
        }
      },
      onLoad: function() {
        var types = ['lecture', 'audio', 'piece'];
        //alert(types);
        $.each(types, function(index, value) {
          //alert(value);
          if (typeof Drupal.settings.islandora_fjm[value] != 'undefined') {   
            var playlist = Drupal.settings.islandora_fjm[value];
            if (playlist.length > 0) {
              Drupal.settings.islandora_fjm.current_type = value;
              Drupal.settings.islandora_fjm.current_index = 0;
              $f().setPlaylist(playlist[0]);
            }
          }
        });
      }
    });

    $f("atm_player").playlist("<? echo $selector; ?>", {
      loop: true,
      template: "<li><a href=\"${url}\">${title}</a></li>",
      manual: false
    });
   });
  
  Drupal.settings.islandora_fjm.play = function (type, piece_index, movement_index) {
    Drupal.settings.islandora_fjm.current_type = type; 
    Drupal.settings.islandora_fjm.current_index = piece_index;
    var piece = Drupal.settings.islandora_fjm[type][piece_index];
    $f().setPlaylist(piece).play(movement_index);
  };
</script>