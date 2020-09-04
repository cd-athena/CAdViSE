#!/bin/bash

sudo yum -y install docker jq &>/dev/null
sudo service docker start

config=$(cat /home/ec2-user/config.json)
title=$(echo "$config" | jq -r '.title')
throttle=$(echo "$config" | jq -r '.throttle')

sudo docker pull "babakt/ppt-server-$title:latest" &>/dev/null

if [[ $throttle == "server" ]]; then
  sudo docker network create ppt-net

  sudo docker pull lukaszlach/docker-tc:latest &>/dev/null
  sudo docker run -d --name docker-tc --network \
    host --cap-add NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock \
    -v /tmp/docker-tc:/tmp/docker-tc lukaszlach/docker-tc

  sudo docker run --rm -d --name ppt-server -p 80:80 --net ppt-net \
    --label "com.docker-tc.enabled=1" \
    --label "com.docker-tc.limit=0kbit" \
    --label "com.docker-tc.delay=0ms" \
    --label "com.docker-tc.loss=0%" \
    --label "com.docker-tc.duplicate=0%" \
    --label "com.docker-tc.corrupt=0%" \
    -v /dev/shm:/dev/shm "babakt/ppt-server-$title"
else
  sudo docker run --rm -d --name ppt-server -p 80:80 -v /dev/shm:/dev/shm "babakt/ppt-server-$title"
fi

exit 0
