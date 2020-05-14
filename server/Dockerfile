FROM node
MAINTAINER babak@itec.aau.at
RUN apt-get update -y && apt-get install -y speedometer

WORKDIR /home/ppt
COPY index.js /home/ppt
COPY package.json /home/ppt
COPY package-lock.json /home/ppt
COPY dataset/ /home/ppt/dataset/
RUN npm i && npm i -g pm2
EXPOSE 80

ENTRYPOINT ["pm2-runtime", "index.js"]
