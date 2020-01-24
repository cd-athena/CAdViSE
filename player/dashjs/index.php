<!doctype html>
<html>
    <head>
        <title>Dash JS Player</title>
        <script type="text/javascript" src="https://cdn.bitmovin.com/analytics/web/2/bitmovinanalytics.min.js"></script>
        <style>
            video {
                width: 640px;
                height: 360px;
            }
        </style>
    </head>
    <body>
        <div>
            <video id="video" autoplay controls></video>
        </div>
        <script type="text/javascript" src="https://cdn.dashjs.org/latest/dash.all.min.js"></script>
        <script>
            document.addEventListener('DOMContentLoaded', () => {
                const url = "https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd";
                const video = document.getElementById('video');
                const time = new Date().getTime();
                const player = dashjs.MediaPlayer().create();
                new bitmovin.analytics.adapters.DashjsAdapter({
                    key: "BITMOVIN_ANALYTICS_LICENSE_ID",
                    videoId: "ppt-test",
                    title: "PPT - Test",
                    cdnProvider: "AKAMAI",
                    experimentName: "<?=$_REQUEST['id']?>",
                    debug: <?=(isset($_REQUEST['mode']) && $_REQUEST['mode']=='debug') ? "true" : "false"?>
                }, player, {starttime: time});
                player.initialize(video, url, true);
            });
        </script>
    </body>
</html>
