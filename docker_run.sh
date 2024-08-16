#!/usr/bin/env bash

SERVER_PORT=51348

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin

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
    bash <(curl -sL https://get.docker.com) >/dev/null 2>&1
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
  command -v docker-compose >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    echo -e "正在安装 Docker Compose"
    wget --no-check-certificate -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" >/dev/null 2>&1
    if [[ $? != 0 ]]; then
      echo -e "${red}下载Compose失败${plain}"
      return 0
    fi
    chmod +x /usr/local/bin/docker-compose
    echo -e "${green}Docker Compose${plain} 安装成功"
  else
    echo -e "${green}Docker Compose${plain} 已安装"
  fi
}

create_docker_file() {
  echo "creating Dockerfile"
  cat >Dockerfile <<-EOF
FROM python:alpine

ENV SERVER_ADDR     0.0.0.0
ENV SERVER_PORT     51348
ENV PASSWORD        jumploop
ENV METHOD          none
ENV PROTOCOL        auth_chain_a
ENV PROTOCOLPARAM   32
ENV OBFS            plain
ENV TIMEOUT         300
ENV DNS_ADDR        8.8.8.8
ENV DNS_ADDR_2      8.8.4.4

ARG BRANCH=manyuser
ARG WORK=/root


RUN apk --no-cache add -U libsodium wget unzip
RUN apk --no-cache add -U tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Shanghai/Asia" > /etc/timezone && apk del tzdata

RUN mkdir -p \$WORK && \
    wget -q --no-check-certificate https://github.com/jumploop/shadowsocksr/archive/refs/heads/\$BRANCH.zip -P \$WORK && \
    unzip \$WORK/\$BRANCH.zip -d \$WORK && rm -rf \$WORK/*.zip && ln -sf /dev/null /var/log/ssserver.log

WORKDIR \$WORK/shadowsocksr-\$BRANCH/shadowsocks

RUN python3 fix_encrypt.py

EXPOSE \$SERVER_PORT
CMD python3 server.py -p \$SERVER_PORT -k \$PASSWORD -m \$METHOD -O \$PROTOCOL -o \$OBFS
EOF
}

clean_docker() {
  docker rmi -f "$(docker images -f "dangling=true" -q)"
  docker stop "$(docker ps -qa -f name=ssr)" && docker rm "$(docker ps -qa -f name=ssr)" && docker rmi "$(docker images -q --filter=reference=ssr)"
  docker system prune -f --all

}

create_docker_container() {
  local port
  port=$1
  docker run -d -p "$port":$SERVER_PORT --restart=always --name ssr${number} ssr
  echo "container map port=$port"
}

create_docker_image() {

  echo "creating docker image"
  docker build --no-cache -t ssr .
  echo "create docker image successfully"
}

main() {
  install_docker
  clean_docker
  create_docker_file
  create_docker_image

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
    create_docker_container "$PORT"
    number=$((number + 1))
  done
}

main
