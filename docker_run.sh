#!/usr/bin/env sh
SERVER_PORT=51348

rpm -q docker || yum -y install docker
systemctl status docker || systemctl start docker
systemctl is-enabled docker || systemctl enable docker
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

docker build -t ssr .
docker run -d  -p $SERVER_PORT:$SERVER_PORT ssr
