#!/bin/bash

config=$(cat /home/ec2-user/config.json)

durations=($(echo "$config" | jq -r '.shapes[].duration'))
ingresses=($(echo "$config" | jq -r '.shapes[].serverIngress'))
egresses=($(echo "$config" | jq -r '.shapes[].serverEgress'))
latencies=($(echo "$config" | jq -r '.shapes[].serverLatency'))

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
