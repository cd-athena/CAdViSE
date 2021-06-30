#!/bin/bash

########################### configurations ###########################
# some of these would be overwritten by arguments passed to the command
players=("bitmovin" "dashjs" "dashjs4" "shaka" "bola" "bba0" "elastic" "fastmpc" "quetra")
experiments=1
shaperDurations=(15)   #s
serverIngresses=(5000) #Kbps
serverEgresses=(5000)  #Kbps
serverLatencies=(80)   #ms
clientIngresses=(5000) #Kbps
clientEgresses=(5000)  #Kbps
clientLatencies=(80)   #ms
id=$(date '+%s')
awsProfile="default"
placementGroup="pptCluster"
awsKey=""
awsIAMRole="SSMEnabled"
awsSecurityGroup="ppt-security-group"
serverInstanceId=""
clientInstanceIds=""
networkConfig=""
analyticsLicenseKey=""
bitmovinAPIKey=""
analyticsOutputId=""
startTime=""
endTime=""
instancesType="m5ad.large"
title="bbb1"
clientWarmupTime=1 #s
########################### /configurations ##########################

########################### functions ############################
showError() {
  now=$(date -u +"%H:%M:%S")
  printf "\e[1;31m>>> [ERROR %s] %s\e[0m\n" "$now" "$1"
  cleanExit 1
}

showMessage() {
  now=$(date -u +"%H:%M:%S")
  printf "\n\e[1;36m>>> [INFO %s] %s\e[0m\n" "$now" "$1"
}

cleanExit() {
  showMessage "Killing EC2 instances and clean ups"
  aws ec2 terminate-instances --instance-ids $clientInstanceIds $serverInstanceId --profile $awsProfile &>/dev/null
  rm -rf "$id"
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
      shaperDurations=($(echo "$networkConfig" | jq '.[].duration'))
      serverIngresses=($(echo "$networkConfig" | jq '.[].serverIngress'))
      serverEgresses=($(echo "$networkConfig" | jq '.[].serverEgress'))
      serverLatencies=($(echo "$networkConfig" | jq '.[].serverLatency'))
      clientIngresses=($(echo "$networkConfig" | jq '.[].clientIngress'))
      clientEgresses=($(echo "$networkConfig" | jq '.[].clientEgress'))
      clientLatencies=($(echo "$networkConfig" | jq '.[].clientLatency'))
      ;;
    "--cluster")
      nextArgumentIndex=$((argumentIndex + 2))
      placementGroup="${!nextArgumentIndex}"
      ;;
    "--title")
      nextArgumentIndex=$((argumentIndex + 2))
      title="${!nextArgumentIndex}"
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
mkdir "$id"

durationOfExperiment=0
for duration in "${shaperDurations[@]}"; do
  durationOfExperiment=$(echo "$durationOfExperiment + $duration" | bc -l)
done

if [[ $durationOfExperiment -gt 596 ]]; then
  showError "Maximum duration of each experiment can not be more than test asset length (09:56)"
fi

showMessage "Running $experiments experiment(s) on the following players for ${durationOfExperiment}s each"
printf '%s ' "${players[@]}"
printf "\n"

showMessage "Spinning up server EC2 instance"
aws ec2 run-instances \
  --image-id ami-0ab838eeee7f316eb \
  --instance-type $instancesType \
  --key-name $awsKey \
  --placement "GroupName = $placementGroup" \
  --iam-instance-profile Name=$awsIAMRole \
  --security-groups $awsSecurityGroup \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ppt-server-$id}]" \
  --profile $awsProfile >"$id/instance.json" || showError "Failed to run the aws command. Check your aws credentials."

serverInstanceId=$(jq -r '.Instances[].InstanceId' <"$id/instance.json")
printf '%s ' "${serverInstanceId[@]}"
printf "\n"

showMessage "Spinning up client EC2 instance(s)"
aws ec2 run-instances \
  --image-id ami-0ab838eeee7f316eb \
  --count ${#players[@]} \
  --instance-type $instancesType \
  --key-name $awsKey \
  --placement "GroupName = $placementGroup" \
  --iam-instance-profile Name=$awsIAMRole \
  --security-groups $awsSecurityGroup \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ppt-client-$id}]" \
  --profile $awsProfile >"$id/instances.json" || showError "Failed to run the aws command. Check your aws credentials."

clientInstanceIds=$(jq -r '.Instances[].InstanceId' <"$id/instances.json")
printf '%s ' "${clientInstanceIds[@]}"
printf "\n"

showMessage "Waiting for instances to be in running state"
stateCodes=0
while [ $stateCodes == 0 ] || [ $(($stateCodesSum / ${#stateCodes[@]})) != 16 ]; do
  stateCodesSum=0
  sleep 3
  stateCodes=($(aws ec2 describe-instances --instance-ids $clientInstanceIds $serverInstanceId --profile $awsProfile | jq '.Reservations[].Instances[].State.Code'))
  for stateCode in "${stateCodes[@]}"; do
    ((stateCodesSum += stateCode))
  done
done
echo "all up [$stateCodesSum]"

clientPublicIps=($(aws ec2 describe-instances --instance-ids $clientInstanceIds --profile $awsProfile | jq -r '.Reservations[].Instances[].PublicIpAddress'))
serverPublicIp=($(aws ec2 describe-instances --instance-ids $serverInstanceId --profile $awsProfile | jq -r '.Reservations[].Instances[].PublicIpAddress'))
serverPrivateIp=$(jq -r '.Instances[].PrivateIpAddress' <"$id/instance.json")
configSkeleton=$(cat configSkeleton.json)

((durationOfExperiment += clientWarmupTime)) # warm up client
config="${configSkeleton/--id--/$id}"
config="${config/--title--/$title}"
config="${config/--alk--/$analyticsLicenseKey}"
config="${config/--serverIp--/$serverPrivateIp}"
config="${config/--experimentDuration--/$durationOfExperiment}"

shaperIndex=0
networkConfig="{
    \"duration\": ${clientWarmupTime},
    \"serverIngress\": 0,
    \"serverEgress\": 0,
    \"serverLatency\": 0,
    \"clientIngress\": 0,
    \"clientEgress\": 0,
    \"clientLatency\": 0
  }"
while [ $shaperIndex -lt "${#shaperDurations[@]}" ]; do
  if [[ $networkConfig != "" ]]; then
    networkConfig+=","
  fi
  networkConfig+="{
    \"duration\": ${shaperDurations[shaperIndex]},
    \"serverIngress\": ${serverIngresses[shaperIndex]},
    \"serverEgress\": ${serverEgresses[shaperIndex]},
    \"serverLatency\": ${serverLatencies[shaperIndex]},
    \"clientIngress\": ${clientIngresses[shaperIndex]},
    \"clientEgress\": ${clientEgresses[shaperIndex]},
    \"clientLatency\": ${clientLatencies[shaperIndex]}
  }"
  ((shaperIndex++))
done
networkConfig="[${networkConfig}]"
config="${config/\"--shapes--\"/$networkConfig}"

playerIndex=0
for publicIp in "${clientPublicIps[@]}"; do
  if [[ $playerIndex == 0 ]]; then
    config="${config/--player--/${players[playerIndex]}}"
  else
    config="${config/${players[playerIndex - 1]}/${players[playerIndex]}}"
  fi
  echo "$config" >"$id/config.json"

  showMessage "Waiting for client network interface to be reachable [${players[playerIndex]}]"
  while ! nc -w5 -z "$publicIp" 22; do
    sleep 1
  done

  showMessage "Injecting scripts and configurations into client instance"
  scp -oStrictHostKeyChecking=no -i "./$awsKey.pem" client/init.sh client/start.sh "$id/config.json" ec2-user@"$publicIp":/home/ec2-user

  ((playerIndex++))
done

showMessage "Waiting for server network interface to be reachable"
while ! nc -w5 -z "$serverPublicIp" 22; do
  sleep 1
done

showMessage "Injecting scripts and configurations into server instance"
scp -oStrictHostKeyChecking=no -i "./$awsKey.pem" server/init.sh server/start.sh "$id/config.json" ec2-user@"$serverPublicIp":/home/ec2-user

showMessage "Executing initializer script(s)"
SSMCommandId=$(aws ssm send-command \
  --instance-ids $clientInstanceIds $serverInstanceId \
  --document-name "AWS-RunShellScript" \
  --comment "Initialize" \
  --parameters commands="/home/ec2-user/init.sh" \
  --output-s3-bucket-name "ppt-output" \
  --output-s3-key-prefix "init-out/$id" \
  --query "Command.CommandId" \
  --profile $awsProfile | sed -e 's/^"//' -e 's/"$//')

echo "$SSMCommandId"

SSMCommandResult="InProgress"
timer=0
while [[ $SSMCommandResult == *"InProgress"* ]]; do
  minutes=$((timer / 60))
  seconds=$((timer % 60))
  printf '\r%s' "~ $minutes:$seconds  "
  if [ $((timer % 5)) == 0 ]; then
    SSMCommandResult=$(aws ssm list-command-invocations --command-id $SSMCommandId --profile $awsProfile | jq -r '.CommandInvocations[].Status')
    sleep 0.4
  else
    sleep 1
  fi
  ((timer += 1))
done
printf "\n"

if [[ $SSMCommandResult == *"Failed"* ]]; then
  showError "Failed to initiate the instance(s). Check the S3 bucket for details"
fi

currentExperiment=0
startTime=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
while [ $currentExperiment -lt $experiments ]; do
  ((currentExperiment++))

  showMessage "Running experiment $currentExperiment of $experiments [+$clientWarmupTime(s) Client warmup time]"
  SSMCommandId=$(aws ssm send-command \
    --instance-ids $clientInstanceIds $serverInstanceId \
    --document-name "AWS-RunShellScript" \
    --comment "Start" \
    --parameters commands="/home/ec2-user/start.sh" \
    --output-s3-bucket-name "ppt-output" \
    --output-s3-key-prefix "start-out/$id" \
    --query "Command.CommandId" \
    --profile $awsProfile | sed -e 's/^"//' -e 's/"$//')

  echo "$SSMCommandId"

  SSMCommandResult="InProgress"
  time=$durationOfExperiment
  timer=$time
  while [[ $SSMCommandResult == *"InProgress"* ]]; do
    minutes=$((timer / 60))
    seconds=$((timer % 60))
    printf '\r%s' "~ $minutes:$seconds  "
    if [ $((timer % 30)) == 0 ] || [[ $((time - timer)) -gt $time ]]; then
      SSMCommandResult=$(aws ssm list-command-invocations --command-id $SSMCommandId --profile $awsProfile | jq -r '.CommandInvocations[].Status')
      sleep 0.4
    else
      sleep 1
    fi
    ((timer -= 1))
  done
  printf "\n"

  if [[ $SSMCommandResult == *"Failed"* ]]; then
    showError "Failed to run experiment(s). Check the S3 bucket for details"
  fi
done

#ppt-analytics-ext-id
endTime=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

showMessage "Requesting the analytics data"
requestResult=$(curl -s -X POST https://api.bitmovin.com/v1/analytics/exports/ \
  -H 'Content-Type: application/json' \
  -H 'X-Api-Key: '$bitmovinAPIKey \
  -d '{
        "startTime": "'$startTime'",
        "endTime": "'$endTime'",
        "name": "ppt-analytics-request-'$id'",
        "licenseKey": "'$analyticsLicenseKey'",
        "output": {
          "outputPath": "analytics/'$id'/",
          "outputId": "'$analyticsOutputId'"
        }
      }')
requestStatus=$(echo "$requestResult" | jq -r '.status')
taskId=$(echo "$requestResult" | jq -r '.data.result.id')
taskStatus=$(echo "$requestResult" | jq -r '.data.result.status')
if [ $taskStatus == 'ERROR' ] || [ $requestStatus == 'ERROR' ]; then
  showError 'Failed to request the analytics data'
  echo $requestResult
else
  echo $taskId
fi

cleanExit 0
