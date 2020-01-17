sudo docker rm -f ppt-debug || sudo docker rm -f ppt-production
sudo docker rm -f docker-tc
sudo docker network rm ppt-net
sudo docker container prune
sudo docker image prune
#sudo docker container ps -a
#sudo docker image ls -a
