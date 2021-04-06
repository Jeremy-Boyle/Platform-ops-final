FROM nginx:latest
RUN rm /etc/apt/sources.list
COPY conf/sources.list /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get full-upgrade -y
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx.key -out nginx.crt -subj "/C=US/ST=Texas/L=Austin/O=Web/CN=platform"
RUN cp nginx.key /etc/ssl/private/nginx.key
RUN cp nginx.crt /etc/ssl/certs/nginx.crt
COPY www/html /usr/share/nginx/html/
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EXPOSE 443