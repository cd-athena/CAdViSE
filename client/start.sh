#!/bin/bash

config=$(cat /home/ec2-user/config.json)
throttle=$(echo "$config" | jq -r '.throttle')
id=$(echo "$config" | jq -r '.id')
alk=$(echo "$config" | jq -r '.alk')
duration=$(($(echo "$config" | jq -r '.experimentDuration') / 1000))
title=$(echo "$config" | jq -r '.title')
player=$(echo "$config" | jq -r '.player')

if [[ $throttle == "server" ]]; then
  sudo docker exec -d "ppt-client-$player" python /home/seluser/ppt/ppt.py "http://localhost/player/$player?id=$id&title=$title&alk=$alk" "$duration"
  sleep $((duration))
else
  durations=($(echo "$config" | jq -r '.shapes[].duration'))
  bandwidths=($(echo "$config" | jq -r '.shapes[].availableBandwidth'))
  delays=($(echo "$config" | jq -r '.shapes[].latency'))
  packetLosses=($(echo "$config" | jq -r '.shapes[].packetLoss'))
  packetDuplicates=($(echo "$config" | jq -r '.shapes[].packetDuplicate'))
  packetCorruptions=($(echo "$config" | jq -r '.shapes[].packetCorruption'))

  sudo docker exec -d "ppt-client-$player" python /home/seluser/ppt/ppt.py "http://localhost/player/$player?id=$id&title=$title&alk=$alk" "$duration"
  sudo docker exec "docker-tc" curl -sd"rate=${bandwidths[0]}kbit&delay=${delays[0]}ms&loss=${packetLosses[0]}%&duplicate=${packetDuplicates[0]}%&corrupt=${packetCorruptions[0]}%" "localhost:4080/ppt-client-$player"
  sleep $((durations[0] / 1000))

  shaperIndex=1
  while [ $shaperIndex -lt "${#durations[@]}" ]; do
    sudo docker exec "docker-tc" curl -sd"rate=${bandwidths[$shaperIndex]}kbit&delay=${delays[$shaperIndex]}ms&loss=${packetLosses[$shaperIndex]}%&duplicate=${packetDuplicates[$shaperIndex]}%&corrupt=${packetCorruptions[$shaperIndex]}%" "localhost:4080/ppt-client-$player"

    sleep $((durations[shaperIndex] / 1000))
    ((shaperIndex++))
  done
fi

exit 0
