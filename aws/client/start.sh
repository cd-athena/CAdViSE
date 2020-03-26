#!/bin/bash

config=$(cat /home/ec2-user/config.json)

id=$(echo "$config" | jq -r '.id')
baseURL=$(echo "$config" | jq -r '.baseURL')
alk=$(echo "$config" | jq -r '.alk')
mpdURL=$(echo "$config" | jq -r '.mpdURL')
duration=$(($(echo "$config" | jq -r '.experimentDuration') / 1000))
mode=$(echo "$config" | jq -r '.mode')
player=$(echo "$config" | jq -r '.player')

sudo docker restart "ppt-$mode-$player" && sudo docker exec -d "ppt-$mode-$player" python /home/seluser/scripts/ppt.py "$baseURL$player/?id=$id&mode=$mode&mpdURL=$mpdURL&alk=$alk" "$duration" "$mode"
sleep $((duration / 1000))
