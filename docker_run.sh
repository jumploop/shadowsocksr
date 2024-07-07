#!/usr/bin/env bash
SERVER_PORT=51348

rpm -q docker || yum -y install docker
systemctl status docker || systemctl start docker
systemctl is-enabled docker || systemctl enable docker
docker stop "$(docker ps -a -q)"
docker rm "$(docker ps -a -q)"
docker rmi "$(docker images -q)"

docker build -t ssr .

read -erp "创建容器的数量(默认: 1):" count
[[ -z ${count} ]] && count=1

create_docker() {
  local port
  port=$1
  docker run -d -p "$port":$SERVER_PORT --restart=always --name ssr${number} ssr
  echo "container map port=$port"
}

number=1
while [ "$number" -le "$count" ]; do
  echo "creating the number $number container"
  if [ "$count" -eq 1 ]; then
    PORT=$SERVER_PORT
  else
    PORT=$(python -c 'import random;print(random.randint(10000, 65536))')
  fi
  create_docker "$PORT"
  number=$((number + 1))
done
