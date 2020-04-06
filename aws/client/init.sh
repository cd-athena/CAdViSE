#!/bin/bash

sudo yum -y install docker jq &>/dev/null
sudo service docker start

config=$(cat /home/ec2-user/config.json)
mode=$(echo "$config" | jq -r '.mode')
throttle=$(echo "$config" | jq -r '.throttle')
player=$(echo "$config" | jq -r '.player')

sudo docker pull babakt/ppt-"$mode":latest &>/dev/null

if [[ $throttle == "server" ]]; then
  sudo docker run --rm -d --name "ppt-$mode-$player" -p 5900:5900 -v /dev/shm:/dev/shm babakt/ppt-"$mode"
else
  sudo docker network create ppt-net

  bandwidths=($(echo "$config" | jq -r '.shapes[].availableBandwidth'))
  delays=($(echo "$config" | jq -r '.shapes[].latency'))
  packetLosses=($(echo "$config" | jq -r '.shapes[].packetLoss'))
  packetDuplicates=($(echo "$config" | jq -r '.shapes[].packetDuplicate'))
  packetCorruptions=($(echo "$config" | jq -r '.shapes[].packetCorruption'))

  sudo docker pull lukaszlach/docker-tc:latest &>/dev/null && sudo docker run -d --name docker-tc --network \
    host --cap-add NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock \
    -v /tmp/docker-tc:/tmp/docker-tc lukaszlach/docker-tc

  sudo docker run --rm -d --name "ppt-$mode-$player" --net ppt-net -p 5900:5900 \
    --label "com.docker-tc.enabled=1" \
    --label "com.docker-tc.limit=${bandwidths[0]}kbit" \
    --label "com.docker-tc.delay=${delays[0]}ms" \
    --label "com.docker-tc.loss=${packetLosses[0]}%" \
    --label "com.docker-tc.duplicate=${packetDuplicates[0]}%" \
    --label "com.docker-tc.corrupt=${packetCorruptions[0]}%" \
    -v /dev/shm:/dev/shm babakt/ppt-"$mode"
fi

exit 0
