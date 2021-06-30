#!/bin/bash

config=$(cat /home/ec2-user/config.json)
id=$(echo "$config" | jq -r '.id')
alk=$(echo "$config" | jq -r '.alk')
duration=$(($(echo "$config" | jq -r '.experimentDuration')))
title=$(echo "$config" | jq -r '.title')
player=$(echo "$config" | jq -r '.player')

sudo docker exec -d "ppt-client-$player" python3 /home/seluser/ppt/ppt.py "http://localhost/player/$player?id=$id&title=$title&alk=$alk" "$duration"

durations=($(echo "$config" | jq -r '.shapes[].duration'))
ingresses=($(echo "$config" | jq -r '.shapes[].clientIngress'))
egresses=($(echo "$config" | jq -r '.shapes[].clientEgress'))
latencies=($(echo "$config" | jq -r '.shapes[].clientLatency'))

shaperIndex=0
while [ $shaperIndex -lt "${#durations[@]}" ]; do

  sudo /home/ec2-user/wondershaper/wondershaper -a eth0 -c

  if [[ ${ingresses[$shaperIndex]} -gt 0 ]] && [[ ${egresses[$shaperIndex]} -gt 0 ]]; then
    sudo /home/ec2-user/wondershaper/wondershaper -a eth0 -d "${ingresses[$shaperIndex]}" -u "${egresses[$shaperIndex]}"
  elif [[ ${ingresses[$shaperIndex]} -gt 0 ]]; then
    sudo /home/ec2-user/wondershaper/wondershaper -a eth0 -d "${ingresses[$shaperIndex]}"
  elif [[ ${egresses[$shaperIndex]} -gt 0 ]]; then
    sudo /home/ec2-user/wondershaper/wondershaper -a eth0 -u "${egresses[$shaperIndex]}"
  elif [[ ${latencies[$shaperIndex]} -gt 0 ]]; then
    sudo tc qdisc replace dev eth0 root netem delay "${latencies[$shaperIndex]}ms"
  fi

  sleep $((durations[shaperIndex]))
  ((shaperIndex++))
done

exit 0
