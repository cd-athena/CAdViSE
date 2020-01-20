<!DOCTYPE html>
<html lang="en">
<head>
    <title>Dash JS Player</title>
<script src="https://cdn.dashjs.org/latest/dash.all.min.js"></script>
<style>
    video {
       width: 640px;
       height: 360px;
    }
</style>
</head>
<body>
   <div>
       <video data-dashjs-player autoplay src="https://dash.akamaized.net/envivio/EnvivioDash3/manifest.mpd" controls></video>
   </div>
</body>
</html>