FROM node
MAINTAINER babak@itec.aau.at

RUN mkdir /home/ppt
COPY index.js /home/ppt
COPY package.json /home/ppt
COPY package-lock.json /home/ppt
COPY dataset/* /home/ppt/dataset
RUN cd /home/ppt && npm install
