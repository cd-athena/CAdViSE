<!DOCTYPE html>
<html lang="en">
<head>
    <title>Bitmovin Player</title>
    <meta charset="UTF-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="https://cdn.bitmovin.com/player/web/8.9.0/bitmovinplayer.js"></script>
    <script type="text/javascript" src="https://cdn.bitmovin.com/analytics/web/1/bitmovinanalytics.min.js"></script>
    <script type="text/javascript">
      customData1 = '' // cdnProvider
      customData2 = '' // abrAlgorithm {abrDynamic / abrBola / abrThroughput}
      customData3 = '' // experimentName
      customData4 = '' // containerVersion
      customData5 = '' // Monroe UUID

      title = ''
      userId = ''
      videoId = ''

      cdnProvider = ''
      experimentName = ''

      abrAlgorithm = ''

    </script>
</head>
<body>

Session ID: <input type="text" size="40" maxlength="15" id="sessionID" name="sID"/>
<script type="text/javascript">
  const sessionID = document.getElementById("sessionID");
</script>

<div id="player"></div>
<script type="text/javascript">

  let qualitySwitches = -1;
  const conf = {
    key: '017bea3e-68e0-4aaf-a5ee-c00e6856ac3b',
    analytics: {
      key: 'a014a94a-489a-4abf-813f-f47303c3912a',
      debug: true,

      title: title,
      userId: userId,
      videoId: videoId,
      customData1: customData1,
      customData2: customData2,
      customData3: customData3,
      customData4: customData4,
      customData5: customData5,
      cdnProvider: cdnProvider,
      experimentName: experimentName
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

    logs: {level: 'debug'},

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
  conf.logs.level = 'debug';

  const source = {
    dash: 'https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd',
  };

  bitmovin.player.Player.addModule(bitmovin.analytics.PlayerModule);
  const player = new bitmovin.player.Player(document.getElementById('player'), conf);

  console.log("DBG || player.analytics.version method: ", player.analytics.version);
  console.log("DBG || window.bitmovin.analytics.version method: ", window.bitmovin.analytics.version);
  console.log("DBG || bitmovin.analytics.version method: ", bitmovin.analytics.version);

  sessionID.value = player.analytics.getCurrentImpressionId();
  console.log("sessionID.value ", sessionID.value);

  player.load(source).then(() => {
  }).catch((reason) => {
    console.error('player setup failed', reason);
  });

</script>

</body>
</html>
