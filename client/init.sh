#!/bin/bash

sudo yum -y install docker jq &>/dev/null
sudo service docker start

config=$(cat /home/ec2-user/config.json)
throttle=$(echo "$config" | jq -r '.throttle')
player=$(echo "$config" | jq -r '.player')

sudo docker pull babakt/ppt-client:latest &>/dev/null

if [[ $throttle == "server" ]]; then
  sudo docker run --rm -d --name "ppt-client-$player" -p 5900:5900 -v /dev/shm:/dev/shm babakt/ppt-client
else
  sudo docker network create ppt-net

  sudo docker pull lukaszlach/docker-tc:latest &>/dev/null
  sudo docker run -d --name docker-tc --network \
    host --cap-add NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock \
    -v /tmp/docker-tc:/tmp/docker-tc lukaszlach/docker-tc

  sudo docker run --rm -d --name "ppt-client-$player" --net ppt-net -p 5900:5900 \
    --label "com.docker-tc.enabled=1" \
    --label "com.docker-tc.limit=0kbit" \
    --label "com.docker-tc.delay=0ms" \
    --label "com.docker-tc.loss=0%" \
    --label "com.docker-tc.duplicate=0%" \
    --label "com.docker-tc.corrupt=0%" \
    -v /dev/shm:/dev/shm babakt/ppt-client
fi

sudo docker cp /home/ec2-user/config.json "ppt-client-$player:/home/seluser/ppt/config.json"
sudo docker exec -d "ppt-client-$player" sudo pm2 start index.js

exit 0
