<!DOCTYPE html>
<html>
  <head>
    <title>Shaka Player</title>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/shaka-player/2.5.6/shaka-player.compiled.js"></script>
    <script type="text/javascript" src="https://cdn.bitmovin.com/analytics/web/2/bitmovinanalytics.min.js"></script>
    <script>
	const manifestUri = 'https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd';

    const initPlayer = () => {
      const video = document.getElementById('video');
      const player = new shaka.Player(video);
      window.player = player;
      player.addEventListener('error', onErrorEvent);
      player.load(manifestUri).then(function() {
        new bitmovin.analytics.adapters.ShakaAdapter({
          key: "BITMOVIN_ANALYTICS_LICENSE_ID",
          videoId: "ppt-test",
          title: "PPT - Test",
          cdnProvider: "AKAMAI",
          experimentName: "<?=$_REQUEST['id']?>",
          debug: <?=(isset($_REQUEST['mode']) && $_REQUEST['mode']=='debug') ? "true" : "false"?>
        }, player);
      }).catch(onError);
    }

    const onErrorEvent = (event) => {
      onError(event.detail);
    }

    const onError = (error) => {
      console.error('Error code', error.code, 'object', error);
    }

    document.addEventListener('DOMContentLoaded', () => {
      shaka.polyfill.installAll();

      if (shaka.Player.isBrowserSupported()) {
        initPlayer();
      } else {
        console.error('Browser not supported!');
      }
    });
    </script>
  </head>
  <body>
    <video id="video" width="640" poster="//shaka-player-demo.appspot.com/assets/poster.jpg" autoplay controls></video>
  </body>
</html>
