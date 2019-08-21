FROM nginx:alpine

COPY configs/nginx.conf /etc/nginx/nginx.conf

RUN mkdir /src

COPY index.html /src