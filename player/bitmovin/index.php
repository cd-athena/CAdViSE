<!DOCTYPE html>
<html lang="en">
<head>
    <title>Bitmovin Player</title>
    <meta charset="UTF-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="https://cdn.bitmovin.com/player/web/8/bitmovinplayer.js"></script>
    <script type="text/javascript" src="https://cdn.bitmovin.com/analytics/web/2/bitmovinanalytics.min.js"></script>
</head>
<body>
<div id="player"></div>
<script type="text/javascript">
  let qualitySwitches = -1;
  const conf = {
    key: '017bea3e-68e0-4aaf-a5ee-c00e6856ac3b',
    analytics: {
      key: "a014a94a-489a-4abf-813f-f47303c3912a",
      videoId: "ppt-test-bitmovin",
      title: "PPT - Bitmovin",
      cdnProvider: "AKAMAI",
      experimentName: "<?=$_REQUEST['id']?>",
      debug: <?=(isset($_REQUEST['mode']) && $_REQUEST['mode']=='debug') ? "true" : "false"?>
    },

    playback: {
      autoplay: true,
      muted: false
    },

    style: {
      width: '640px',
      height: '360px',
      controls: true
    },

    events: {
      videodownloadqualitychange: () => {
        ++qualitySwitches;
        console.log("adaptation --->", qualitySwitches);
      },

      play: (e) => {
        initTime = new Date().getTime();
        console.log("PLAY --->", initTime);
      },

      stallstarted: (e) => {
        console.log("STALL --->", initTime);
      },
    }
  };

  const source = {
    dash: 'https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd',
  };

  bitmovin.player.Player.addModule(bitmovin.analytics.PlayerModule);
  const player = new bitmovin.player.Player(document.getElementById('player'), conf);

  player.load(source).then(() => {
    console.log('Loaded!')
  }).catch((reason) => {
    console.error('player setup failed', reason);
  });

</script>

</body>
</html>
