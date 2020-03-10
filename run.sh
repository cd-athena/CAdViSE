#!/bin/bash

########################### configurations ###########################
# some of these would be overwritten by arguments passed to the command
mode="production"
baseURL="http://ppt-players.s3-website.eu-central-1.amazonaws.com/"
players=("bitmovin" "dashjs" "shaka")
experiments=1
shaperDurations=(15000)     #ms
shaperDelays=(70)           #ms
shaperBandwidths=(5000)     #kbits
shaperPacketLosses=(0)      #percentage
shaperPacketDuplicates=(0)  #percentage
shaperPacketCorruptions=(0) #percentage
newBuild=0
id=$(python -c 'import time; print time.time()' | cut -c1-10)
awsProfile=""
awsKey=""
awsIAMRole=""
awsSecurityGroup=""
instanceIds=""
networkConfig=""
analyticsLicenseKey=""
mpdURL=""
########################### /configurations ##########################

########################### functions ############################
showError() {
  now=$(python -c 'import time; print time.time()')
  printf "\e[1;31m>>> [ERROR %.2f] %s\e[0m\n" "$now" "$1"
  cleanExit 1
}

showMessage() {
  now=$(python -c 'import time; print time.time()')
  printf "\n\e[1;36m>>> [INFO %.2f] %s\e[0m\n" "$now" "$1"
}

cleanExit() {
  if [[ $awsProfile != "" ]]; then
    showMessage "Killing EC2 instances"
    aws ec2 terminate-instances --instance-ids $instanceIds --profile $awsProfile &>/dev/null
  else
    showMessage "Removing docker containers"
    for player in "${players[@]}"; do
      sudo docker rm -f "ppt-$mode-$player" &>/dev/null
    done
    sudo docker rm -f docker-tc &>/dev/null
    sudo docker network rm ppt-net &>/dev/null
  fi
  exit $1
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
      if [[ ! $experiments =~ ^[0-9]+$ ]]; then
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
      ;;
    "--debug")
      mode="debug"
      ;;
    "--build")
      newBuild=1
      ;;
    "--awsProfile")
      nextArgumentIndex=$((argumentIndex + 2))
      awsProfile="${!nextArgumentIndex}"
      ;;
    "--awsKey")
      nextArgumentIndex=$((argumentIndex + 2))
      awsKey="${!nextArgumentIndex}"
      ;;
    "--awsIAMRole")
      nextArgumentIndex=$((argumentIndex + 2))
      awsIAMRole="${!nextArgumentIndex}"
      ;;
    "--awsSecurityGroup")
      nextArgumentIndex=$((argumentIndex + 2))
      awsSecurityGroup="${!nextArgumentIndex}"
      ;;
    "--players")
      valueIndex=0
      newPlayers=()
      for value in "$@"; do
        if [[ $valueIndex -gt $argumentIndex ]]; then
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

durationOfExperiment=0
for duration in "${shaperDurations[@]}"; do
  durationOfExperiment=$(echo "$durationOfExperiment + $duration" | bc -l)
done

if [[ $durationOfExperiment -gt 596000 ]]; then
  showError "Maximum duration of each experiment can not be more than current test video length (09:56)"
fi

showMessage "Running $experiments experiment(s) in $mode mode on the following players for ${durationOfExperiment}ms each"
printf '%s ' "${players[@]}"
printf "\n"

if [[ $newBuild == 1 ]]; then
  showMessage "Building ppt-$mode docker image"
  docker build --network=host --no-cache --rm=true --file ppt-$mode.docker --tag babakt/ppt-$mode .
fi

if [[ $awsProfile != "" ]]; then
  showMessage "Spinning up EC2 instance(s)"

  aws ec2 run-instances \
    --image-id ami-0ab838eeee7f316eb \
    --count ${#players[@]} \
    --instance-type t2.medium \
    --key-name $awsKey \
    --iam-instance-profile Name=$awsIAMRole \
    --security-groups $awsSecurityGroup \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ppt-$id}]" \
    --profile $awsProfile >instances.json || showError "Failed to run the aws command. Check your aws credentials."

  instanceIds=$(jq -r '.Instances[].InstanceId' <instances.json)
  printf '%s ' "${instanceIds[@]}"
  printf "\n"

  stateCodes=0
  while [ $stateCodes == 0 ] || [ $(($stateCodesSum / ${#stateCodes[@]})) != 16 ]; do
    stateCodesSum=0
    sleep 3
    stateCodes=($(aws ec2 describe-instances --instance-ids $instanceIds --profile $awsProfile | jq '.Reservations[].Instances[].State.Code'))
    for stateCode in "${stateCodes[@]}"; do
      ((stateCodesSum += stateCode))
    done
  done

  publicIps=($(aws ec2 describe-instances --instance-ids $instanceIds --profile $awsProfile | jq -r '.Reservations[].Instances[].PublicIpAddress'))

  configSkeleton=$(cat aws/configSkeleton.json)
  config="${configSkeleton/--id--/$id}"
  config="${config/--mode--/$mode}"
  config="${config/--baseURL--/$baseURL}"
  config="${config/--alk--/$analyticsLicenseKey}"
  config="${config/--mpdURL--/$mpdURL}"
  config="${config/--experimentDuration--/$durationOfExperiment}"
  if [[ $networkConfig == "" ]]; then
    networkConfig="{
      \"duration\": ${shaperDurations[0]},
      \"availableBandwidth\": ${shaperBandwidths[0]},
      \"latency\": ${shaperDelays[0]},
      \"packetLoss\": ${shaperPacketLosses[0]},
      \"packetDuplicate\": ${shaperPacketDuplicates[0]},
      \"packetCorruption\": ${shaperPacketCorruptions[0]}
    }"
  fi
  config="${config/\"--shapes--\"/$networkConfig}"

  playerIndex=0
  for publicIp in "${publicIps[@]}"; do
    if [[ $playerIndex == 0 ]]; then
      config="${config/--player--/${players[playerIndex]}}"
    else
      config="${config/${players[playerIndex - 1]}/${players[playerIndex]}}"
    fi
    echo "$config" >"aws/config.json"

    showMessage "Waiting for network interface to be reachable [${players[playerIndex]}]"
    while ! nc -w5 -z "$publicIp" 22; do
      sleep 1
    done

    showMessage "Injecting scripts and configurations into instance"
    scp -oStrictHostKeyChecking=no -i "./aws/$awsKey.pem" aws/init.sh aws/start.sh aws/config.json ec2-user@"$publicIp":/home/ec2-user
    rm -f "aws/config.json"

    ((playerIndex++))
  done

  showMessage "Executing initializer script(s)"
  SSMCommandId=$(aws ssm send-command \
    --instance-ids $instanceIds \
    --document-name "AWS-RunShellScript" \
    --comment "Initialize" \
    --parameters commands="/home/ec2-user/init.sh" \
    --output-s3-bucket-name "ppt-output" \
    --output-s3-key-prefix "init-out/$id" \
    --query "Command.CommandId" \
    --profile $awsProfile | sed -e 's/^"//' -e 's/"$//')

  echo "$SSMCommandId"

  SSMCommandResult="InProgress"
  while [[ $SSMCommandResult == *"InProgress"* ]]; do
    sleep 5
    SSMCommandResult=$(aws ssm list-command-invocations --command-id $SSMCommandId --profile $awsProfile | jq -r '.CommandInvocations[].Status')
  done
  echo "$SSMCommandResult"

  if [[ $SSMCommandResult == *"Failed"* ]]; then
    showError "Failed to initiate the instance(s). Check the S3 bucket for details"
  fi

  currentExperiment=0
  while [ $currentExperiment -lt $experiments ]; do
    ((currentExperiment++))

    showMessage "Executing start script(s) for experiment $currentExperiment"
    SSMCommandId=$(aws ssm send-command \
      --instance-ids $instanceIds \
      --document-name "AWS-RunShellScript" \
      --comment "Start" \
      --parameters commands="/home/ec2-user/start.sh" \
      --output-s3-bucket-name "ppt-output" \
      --output-s3-key-prefix "start-out/$id" \
      --query "Command.CommandId" \
      --profile $awsProfile | sed -e 's/^"//' -e 's/"$//')

    echo "$SSMCommandId"

    SSMCommandResult="InProgress"
    while [[ $SSMCommandResult == *"InProgress"* ]]; do
      sleep 5
      SSMCommandResult=$(aws ssm list-command-invocations --command-id $SSMCommandId --profile $awsProfile | jq -r '.CommandInvocations[].Status')
    done
    echo "$SSMCommandResult"

    if [[ $SSMCommandResult == *"Failed"* ]]; then
      showError "Failed to start the experiment(s). Check the S3 bucket for details"
    fi

  done

else
  showMessage "Creating docker network"
  sudo docker network create ppt-net || (sudo docker network rm ppt-net && sudo docker network create ppt-net) || showError "Failed to create docker network"

  showMessage "Containerizing traffic control image"
  sudo docker run -d --name docker-tc --network host --cap-add NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/docker-tc:/tmp/docker-tc lukaszlach/docker-tc || showError "Failed to containerize the traffic control image"

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

    ((vncPort++))
  done

  currentExperiment=0
  while [ $currentExperiment -lt $experiments ]; do
    ((currentExperiment++))

    showMessage "Running the tests with selenium for the next ${shaperDurations[0]}ms in experiment $currentExperiment"
    echo "Set rate=${shaperBandwidths[0]}kbit, delay=${shaperDelays[0]}ms, loss=${shaperPacketLosses[0]}%, duplicate=${shaperPacketDuplicates[0]}%, corrupt=${shaperPacketCorruptions[0]}%"
    for player in "${players[@]}"; do
      sudo docker exec -d "ppt-$mode-$player" python /home/seluser/scripts/ppt.py "$baseURL$player/?id=$id&mode=$mode&mpdURL=$mpdURL&alk=$analyticsLicenseKey" "$durationOfExperiment" $mode
    done

    sleep $((shaperDurations / 1000))

    shaperIndex=1
    while [ $shaperIndex -lt "${#shaperDurations[@]}" ]; do
      showMessage "Reshaping the network for the next ${shaperDurations[$shaperIndex]}ms in experiment $currentExperiment"
      echo "Set rate=${shaperBandwidths[$shaperIndex]}kbit, delay=${shaperDelays[$shaperIndex]}ms, loss=${shaperPacketLosses[$shaperIndex]}%, duplicate=${shaperPacketDuplicates[$shaperIndex]}%, corrupt=${shaperPacketCorruptions[$shaperIndex]}%"

      for player in "${players[@]}"; do
        sudo docker exec "docker-tc" curl -sd"rate=${shaperBandwidths[$shaperIndex]}kbit&delay=${shaperDelays[$shaperIndex]}ms&loss=${shaperPacketLosses[$shaperIndex]}%&duplicate=${shaperPacketDuplicates[$shaperIndex]}%&corrupt=${shaperPacketCorruptions[$shaperIndex]}%" "localhost:4080/ppt-$mode-$player" &>/dev/null
      done

      sleep $((shaperDurations[shaperIndex] / 1000))
      ((shaperIndex++))
    done
  done
fi

cleanExit 0
