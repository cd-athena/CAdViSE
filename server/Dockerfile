FROM node
MAINTAINER babak@itec.aau.at

WORKDIR /home/ppt
COPY index.js /home/ppt
COPY package.json /home/ppt
COPY package-lock.json /home/ppt
RUN mkdir -p /home/ppt/dataset/
COPY dataset/bbb /home/ppt/dataset/bbb
RUN npm i && npm i -g pm2
EXPOSE 80

ENTRYPOINT ["pm2-runtime", "index.js"]
