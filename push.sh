#!/bin/bash

CONTAINERTAG='babakt/ppt-debug:latest'

#docker login --username=yourhubusername --password=yourpassword
docker login --username= --password= && docker push ${CONTAINERTAG} && echo "Finished uploading ${CONTAINERTAG}"
