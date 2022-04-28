FROM node
MAINTAINER babak.taraghi@aau.at

WORKDIR /home/ppt
COPY index.js /home/ppt
COPY package.json /home/ppt
COPY package-lock.json /home/ppt
RUN mkdir -p /home/ppt/dataset
RUN wget --no-parent --recursive ftp://ftp.itec.aau.at/datasets/mmsys22/Seconds_That_Count/4sec/avc/
RUN mv ftp.itec.aau.at/datasets/mmsys22/Seconds_That_Count/4sec/avc/ /home/ppt/dataset/stc/
RUN npm i && npm i -g pm2
EXPOSE 80

ENTRYPOINT ["pm2-runtime", "index.js"]
