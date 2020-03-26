FROM node
MAINTAINER babak@itec.aau.at

WORKDIR /home/ppt
COPY index.js /home/ppt
COPY package.json /home/ppt
COPY package-lock.json /home/ppt
COPY dataset/ /home/ppt/dataset/
RUN npm i && npm audit fix
RUN npm i -g pm2
EXPOSE 80

ENTRYPOINT ["pm2-runtime", "index.js"]
