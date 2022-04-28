#!/bin/bash

sudo yum -y install docker jq git &>/dev/null

sudo mv /var/lib/docker /dev/
sudo mkdir /var/lib/docker
sudo mount --rbind /dev/docker /var/lib/docker

sudo service docker start
sudo git clone https://github.com/cd-athena/wondershaper.git /home/ec2-user/wondershaper

sudo docker pull "babakt/ppt-server:cadvise" &>/dev/null
sudo docker run --rm -d --name ppt-server -p 80:80 -v /dev/shm:/dev/shm "babakt/ppt-server:cadvise"

exit 0
