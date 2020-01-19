### Adaptive Streaming Players Performance Testbed
This is based on https://github.com/ValBr11/docker-evaluation-players
- Works with multi players
- Configurable network attributes are `availableBandwidth`, `latency` and `packetLoss`
 
#### Requirements
- docker
- python 2.7 or higher
- jq (https://stedolan.github.io/jq)

#### Running the test
```
$ sudo ./run.sh --debug --players bitmovin --shaper network.json
```
- Passing `--build` would cause the image to be built on your local machine instead of being fetched from dockerhub.
- `--players` accepts three values `bitmovin`, `shaka` and `dashJs`
- Omitting `--debug` would cause the test to be executed in production mode
- Update network simulator values such as available bandwidth in `network.json`

#### Monitoring in debug mode
Use VNC client to connect to `127.0.0.1:5900` while the test is running.
To monitor multiple players, increase the port number by 1 (eg. `127.0.0.1:5901`) for the next player which was passed to `--players`. 
