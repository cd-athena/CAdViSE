<!doctype html>
<html>
    <head>
        <title>Dash JS Player</title>
        <style>
            video {
                width: 640px;
                height: 360px;
            }
        </style>
    </head>
    <body>
        <div>
            <video id="video" controls></video>
        </div>
        <script src="https://cdn.dashjs.org/latest/dash.all.min.js"></script>
        <script type="text/javascript" src="https://cdn.bitmovin.com/analytics/web/2/bitmovinanalytics.min.js"></script>
        <script>
            (function(){
                const url = "https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd";
                const video = document.getElementById('video');
                const time = new Date().getTime();
                const player = dashjs.MediaPlayer().create();
                new bitmovin.analytics.adapters.DashjsAdapter({
                  key: "a014a94a-489a-4abf-813f-f47303c3912a",
                  videoId: "ppt-test-dashJS",
                  title: "PPT - DashJs",
                  cdnProvider: "AKAMAI",
                  experimentName: "<?=$_REQUEST['id']?>",
                  debug: <?=(isset($_REQUEST['mode']) && $_REQUEST['mode']=='debug') ? "true" : "false"?>
                }, player, {starttime: time});
                player.initialize(video, url, true);
            })();
        </script>
    </body>
</html>
