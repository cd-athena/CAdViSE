#!/bin/bash

sudo mkdir /var/run/supervisor
sudo chmod -R 777 /var/run/supervisor
sudo chgrp -R 0 /var/run/supervisor
sudo chmod -R g=u /var/run/supervisor

sudo -u seluser /opt/bin/entry_point.sh

