#!/bin/bash

########################### configurations ###########################
# some of these would be overwritten by arguments passed to the command
mode="production"
baseURL="https://www.itec.aau.at/~babak/player/"
players=("bitmovin" "dashJS" "shaka")
experiments=1
shaperDurations=(15 15 20 10 15)          #sec
shaperDelays=(70 70 70 70 70)             #ms
shaperBandwidths=(5000 1000 3000 500 100) #kbits
shaperPacketLosses=(0 0 0 0 0)            # percentage
newBuild=0
id=$(python -c 'import time; print time.time()')
########################### /configurations ##########################

########################### functions ############################
showError() {
  now=$(python -c 'import time; print time.time()')
  printf "\e[1;31m>>> [ERROR %.2f] %s\e[0m\n" "$now" "$1"
  sudo docker rm -f ppt-$mode &>/dev/null
  sudo docker rm -f docker-tc &>/dev/null
  sudo docker network rm ppt-net &>/dev/null
  exit 1
}

showMessage() {
  now=$(python -c 'import time; print time.time()')
  printf "\n\e[1;36m>>> [INFO %.2f] %s\e[0m\n" "$now" "$1"
}
########################### /functions ###########################

########################### arguments ############################
argumentIndex=0
for argument in "$@"; do
  if [[ $argument == *"--"* ]]; then
    case $argument in
    "--experiments")
      nextArgumentIndex=$((argumentIndex + 2))
      experiments="${!nextArgumentIndex}"
      if ! [[ $experiments =~ ^[0-9]+$ ]]; then
        showError "Experiments parameter should follow by an integer number"
      fi
      ;;
    "--shaper")
      nextArgumentIndex=$((argumentIndex + 2))
      networkConfigFileName="${!nextArgumentIndex}"
      networkConfig=$(cat $networkConfigFileName) || showError "Could not load the network config file"
      shaperDelays=($(echo "$networkConfig" | jq '.[].latency'))
      shaperDurations=($(echo "$networkConfig" | jq '.[].duration'))
      shaperBandwidths=($(echo "$networkConfig" | jq '.[].availableBandwidth'))
      shaperPacketLosses=($(echo "$networkConfig" | jq '.[].packetLoss'))
      shaperPacketDuplicates=($(echo "$networkConfig" | jq '.[].packetDuplicate'))
      shaperPacketCorruptions=($(echo "$networkConfig" | jq '.[].packetCorruption'))
      "packetCorruption": 0
      ;;
    "--debug")
      mode="debug"
      ;;
    "--build")
      newBuild=1
      ;;
    "--players")
      valueIndex=0
      newPlayers=()
      for value in "$@"; do
        if [[ ! $valueIndex < $argumentIndex && $valueIndex != $argumentIndex ]]; then
          if [[ $value == *"--"* ]]; then
            break
          fi
          if [[ " ${players[@]} " =~ " ${value} " ]]; then
            newPlayers+=($value)
          else
            showError "Invalid player '$value'"
          fi
        fi
        ((valueIndex++))
      done
      if [[ ${#newPlayers[@]} -lt 1 ]]; then
        showError "Define at least one player"
      fi
      players=(${newPlayers[@]})
      ;;
    *)
      showError "Invalid argument '$argument'"
      ;;
    esac
  fi
  ((argumentIndex++))
done
########################### /arguments ############################

printf "\n\e[1;33m>>> Experiment set id: $id %s\e[0m\n"
showMessage "Running $experiments experiment(s) in $mode mode on following players:"
printf '%s ' "${players[@]}"
printf "\n"

showMessage "Creating docker network"
sudo docker network create ppt-net || (sudo docker network rm ppt-net && sudo docker network create ppt-net) || showError "Failed to create docker network"

showMessage "Containerizing traffic control image"
sudo docker run -d --name docker-tc --network host --cap-add NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/docker-tc:/tmp/docker-tc lukaszlach/docker-tc || showError "Failed to containerize the traffic control image"

if [[ $newBuild == 1 ]]; then
  showMessage "Building ppt-$mode docker image"
  docker build --network=host --no-cache --rm=true --file ppt-$mode.docker --tag babakt/ppt-$mode .
fi

durationOfExperiment=0
for duration in "${shaperDurations[@]}"; do
  durationOfExperiment=$(echo "$durationOfExperiment + $duration" | bc -l)
done

vncPort=5900
for player in "${players[@]}"; do
  showMessage "Containerizing the ppt-$mode image for $player player"
  sudo docker run --rm -d --name "ppt-$mode-$player" --net ppt-net -p $vncPort:5900 \
    --label "com.docker-tc.enabled=1" \
    --label "com.docker-tc.limit=${shaperBandwidths[0]}kbit" \
    --label "com.docker-tc.delay=${shaperDelays[0]}ms" \
    --label "com.docker-tc.loss=${shaperPacketLosses[0]}%" \
    --label "com.docker-tc.duplicate=${shaperPacketDuplicates[0]}%" \
    --label "com.docker-tc.corrupt=${shaperPacketCorruptions[0]}%" \
    -v /dev/shm:/dev/shm babakt/ppt-$mode || showError "Failed to run docker command, maybe build again with --build?"

  vncPort=$((vncPort + 1))
  sleep 1
done

for player in "${players[@]}"; do
  showMessage "Executing python script for $player player"
  sudo docker exec -d "ppt-$mode-$player" python /home/seluser/scripts/ppt.py "$baseURL$player/?id=$id&mode=$mode" $experiments "$durationOfExperiment" $mode
done

currentExperiment=0
while [ $currentExperiment -lt $experiments ]; do
  currentExperiment=$((currentExperiment + 1))

  for player in "${players[@]}"; do
    sudo docker exec "docker-tc" curl -sd"rate=${shaperBandwidths[0]}kbit" "localhost:4080/ppt-$mode-$player"
  done
done

for j in $(seq $experiments); do
  m=0
  k=1
  l=0

  for player in "${players[@]}"; do
    sudo docker exec "docker-tc" curl -sd"rate=${shaperBandwidths[0]}kbit" "localhost:4080/ppt-$mode-$player"
  done

  for i in $(seq $durationOfExperiment); do
    let "time_seg = $(echo ${shaperDurations[$l]})"
    let "time_t = time_seg + m"
    if (($i == $time_t)); then #test if we change segment
      let "m = i"
      rate=${shaperBandwidths[$k]}
      for player in "${players[@]}"; do
        sudo docker exec "docker-tc" curl -sd"rate= $rate kbit" "localhost:4080/ppt-$mode-$player"
      done
      k=$((k + 1))
      l=$((l + 1))
    fi
    echo "Experiment $j/$experiments"
    t=$((t + 1))
    Time=$(($durationOfExperiment * $experiments))
    time_exp=$((Time - t))
    min=$((time_exp / 60))
    sec=$((time_exp % 60))
    min_exp=$(($Time / 60))
    sec_exp=$(($Time % 60))
    echo "Full time = $min_exp:$sec_exp min"
    echo "Time to end = $min:$sec min"
    echo " "
    sleep 1
    i=$((i + 1))
  done
  i=0
done

showMessage "Removing the resources gracefully"
sleep 2
for player in "${players[@]}"; do
  sudo docker rm -f "ppt-$mode-$player"
done
sudo docker rm -f docker-tc
sudo docker network rm ppt-net

exit 0
