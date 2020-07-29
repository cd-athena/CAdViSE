#!/bin/bash

config=$(cat /home/ec2-user/config.json)
throttle=$(echo "$config" | jq -r '.throttle')

if [[ $throttle == "server" ]]; then
  durations=($(echo "$config" | jq -r '.shapes[].duration'))
  bandwidths=($(echo "$config" | jq -r '.shapes[].availableBandwidth'))
  delays=($(echo "$config" | jq -r '.shapes[].latency'))
  packetLosses=($(echo "$config" | jq -r '.shapes[].packetLoss'))
  packetDuplicates=($(echo "$config" | jq -r '.shapes[].packetDuplicate'))
  packetCorruptions=($(echo "$config" | jq -r '.shapes[].packetCorruption'))

  shaperIndex=0
  while [ $shaperIndex -lt "${#durations[@]}" ]; do
    sudo docker exec "docker-tc" curl -sd"rate=${bandwidths[$shaperIndex]}kbit&delay=${delays[$shaperIndex]}ms&loss=${packetLosses[$shaperIndex]}%&duplicate=${packetDuplicates[$shaperIndex]}%&corrupt=${packetCorruptions[$shaperIndex]}%" "localhost:4080/ppt-server"

    sleep $((durations[shaperIndex] / 1000))
    ((shaperIndex++))
  done
fi

exit 0
