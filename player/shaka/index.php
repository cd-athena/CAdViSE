<!DOCTYPE html>
<html>
  <head>
    <title>Shaka Player</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/shaka-player/2.5.6/shaka-player.compiled.js"></script>
    <script type="text/javascript" src="https://cdn.bitmovin.com/analytics/web/2/bitmovinanalytics.min.js"></script>
    <script>
	const manifestUri = 'https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd';

    function initApp() {
      // Install built-in polyfills to patch browser incompatibilities.
      shaka.polyfill.installAll();

      // Check to see if the browser supports the basic APIs Shaka needs.
      if (shaka.Player.isBrowserSupported()) {
        // Everything looks good!
        initPlayer();
      } else {
        // This browser does not have the minimum set of APIs we need.
        console.error('Browser not supported!');
      }
    }

    function initPlayer() {
      // Create a Player instance.
      const video = document.getElementById('video');
      const player = new shaka.Player(video);

      // Attach player to the window to make it easy to access in the JS console.
      window.player = player;

      // Listen for error events.
      player.addEventListener('error', onErrorEvent);

      // Try to load a manifest.
      // This is an asynchronous process.
      player.load(manifestUri).then(function() {
        // This runs if the asynchronous load is successful.

        new bitmovin.analytics.adapters.ShakaAdapter({
          key: "a014a94a-489a-4abf-813f-f47303c3912a",
          videoId: "ppt-test-shaka",
          title: "PPT - Shaka",
          cdnProvider: "AKAMAI",
          experimentName: "<?=$_REQUEST['id']?>",
          debug: <?=(isset($_REQUEST['mode']) && $_REQUEST['mode']=='debug') ? "true" : "false"?>
        }, player);

      }).catch(onError);  // onError is executed if the asynchronous load fails.
    }

    function onErrorEvent(event) {
      // Extract the shaka.util.Error object from the event.
      onError(event.detail);
    }

    function onError(error) {
      // Log the error.
      console.error('Error code', error.code, 'object', error);
    }

    document.addEventListener('DOMContentLoaded', initApp);
    </script>
  </head>
  <body>
    <video id="video" width="640" poster="//shaka-player-demo.appspot.com/assets/poster.jpg" autoplay controls></video>
  </body>
</html>
