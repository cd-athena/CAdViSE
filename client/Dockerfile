FROM selenium/standalone-chrome-debug:latest
MAINTAINER babak@itec.aau.at

RUN sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
RUN sudo apt-get update && sudo apt-get install -y nodejs python3-pip
RUN pip install selenium

WORKDIR /home/seluser/ppt

COPY ppt.py .
RUN sudo chmod 755 ./ppt*.py

COPY player ./player
COPY index.js .
COPY package.json .
COPY package-lock.json .

RUN sudo npm i && sudo npm i -g pm2
