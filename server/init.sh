#!/bin/bash

sudo yum -y install docker jq git &>/dev/null

sudo service docker start
sudo git clone https://github.com/cd-athena/wondershaper.git /home/ec2-user/wondershaper

config=$(cat /home/ec2-user/config.json)
title=$(echo "$config" | jq -r '.title')

sudo docker pull "babakt/ppt-server-$title:latest" &>/dev/null
sudo docker run --rm -d --name ppt-server -p 80:80 -v /dev/shm:/dev/shm "babakt/ppt-server-$title"

exit 0
