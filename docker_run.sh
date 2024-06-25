#!/usr/bin/env sh

rpm -q docker || yum -y install docker
systemctl status docker || systemctl start docker

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

docker build -t ssr .
docker run -d  -p 51348:51348 ssr
