FROM debian:bullseye
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install nodejs npm -y
RUN mkdir /usr/src/node
WORKDIR /usr/src/node
COPY conf/nodejs-app/package*.json ./
COPY conf/nodejs-app/server.js ./
RUN npm install
CMD [ "node", "server.js" ]
EXPOSE 8080