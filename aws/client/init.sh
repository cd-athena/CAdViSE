#!/bin/bash

sudo yum -y install docker jq &>/dev/null
sudo service docker start

config=$(cat /home/ec2-user/config.json)

mode=$(echo "$config" | jq -r '.mode')
player=$(echo "$config" | jq -r '.player')

sudo docker pull babakt/ppt-"$mode":latest &>/dev/null && sudo docker run --rm -d --name "ppt-$mode-$player" -p 5900:5900 -v /dev/shm:/dev/shm babakt/ppt-"$mode"
