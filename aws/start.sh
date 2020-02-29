#!/bin/bash

config=$(cat /home/ec2-user/config.json)

id=$(echo "$config" | jq -r '.id')
baseURL=$(echo "$config" | jq -r '.baseURL')
alk=$(echo "$config" | jq -r '.alk')
mpdURL=$(echo "$config" | jq -r '.mpdURL')
duration=$(($(echo "$config" | jq -r '.experimentDuration') / 1000))
mode=$(echo "$config" | jq -r '.mode')
player=$(echo "$config" | jq -r '.player')
durations=($(echo "$config" | jq -r '.shapes[].duration'))
bandwidths=($(echo "$config" | jq -r '.shapes[].availableBandwidth'))
delays=($(echo "$config" | jq -r '.shapes[].latency'))
packetLosses=($(echo "$config" | jq -r '.shapes[].packetLoss'))
packetDuplicates=($(echo "$config" | jq -r '.shapes[].packetDuplicate'))
packetCorruptions=($(echo "$config" | jq -r '.shapes[].packetCorruption'))

sudo docker exec "docker-tc" curl -sd"rate=${bandwidths[0]}kbit&delay=${delays[0]}ms&loss=${packetLosses[0]}%&duplicate=${packetDuplicates[0]}%&corrupt=${packetCorruptions[0]}%" "localhost:4080/ppt-$mode-$player"
sudo docker restart "ppt-$mode-$player" && sudo docker exec -d "ppt-$mode-$player" python /home/seluser/scripts/ppt.py "$baseURL$player/?id=$id&mode=$mode&mpdURL=$mpdURL&alk=$alk" "$duration" "$mode"
sleep $((durations[0] / 1000))

shaperIndex=1
while [ $shaperIndex -lt "${#durations[@]}" ]; do
  echo "rate=${bandwidths[$shaperIndex]}kbit&delay=${delays[$shaperIndex]}ms&loss=${packetLosses[$shaperIndex]}%&duplicate=${packetDuplicates[$shaperIndex]}%&corrupt=${packetCorruptions[$shaperIndex]}%"
  sudo docker exec "docker-tc" curl -sd"rate=${bandwidths[$shaperIndex]}kbit&delay=${delays[$shaperIndex]}ms&loss=${packetLosses[$shaperIndex]}%&duplicate=${packetDuplicates[$shaperIndex]}%&corrupt=${packetCorruptions[$shaperIndex]}%" "localhost:4080/ppt-$mode-$player"

  sleep $((durations[shaperIndex] / 1000))
  ((shaperIndex++))
done
