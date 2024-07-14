#!/usr/bin/env bash

SERVER_PORT=51348

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

install_soft() {
  (command -v yum >/dev/null 2>&1 && yum install "$*" -y) ||
    (command -v apt >/dev/null 2>&1 && apt install "$*" -y) ||
    (command -v pacman >/dev/null 2>&1 && pacman -Syu "$*") ||
    (command -v apt-get >/dev/null 2>&1 && apt-get install "$*" -y)

  if [[ $? != 0 ]]; then
    echo -e "${red}安装基础软件失败，稍等会${plain}"
    exit 1
  fi

  (command -v pip3 >/dev/null 2>&1 && pip3 install requests)
}

install_base() {
  (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v pip3 >/dev/null 2>&1) || install_soft curl wget python3-pip python3
}

install_docker() {
  install_base
  command -v docker >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    install_base
    echo -e "正在安装 Docker"
    curl -sLo install.sh https://get.docker.com
    bash install.sh >/dev/null 2>&1
    # bash <(curl -sL https://get.docker.com) >/dev/null 2>&1
    if [[ $? != 0 ]]; then
      echo -e "${red}下载Docker失败${plain}"
      exit 1
    fi
    systemctl enable docker.service
    systemctl start docker.service
    echo -e "${green}Docker${plain} 安装成功"
  else
    echo -e "${green}Docker${plain} 已安装"

  fi
}

clean_docker() {
  docker stop $(docker ps -qa -f name=ssr) && docker rm $(docker ps -qa -f name=ssr) && docker images -q --filter=reference=ssr
}

create_docker() {
  local port
  port=$1
  docker run -d -p "$port":$SERVER_PORT --restart=always --name ssr${number} ssr
  echo "container map port=$port"
}

clean_docker
docker build -t ssr .

read -erp "创建容器的数量(默认: 1):" count
[[ -z ${count} ]] && count=1

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
