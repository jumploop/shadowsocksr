#!/usr/bin/env bash

SERVER_PORT=51348

DOCKER_COMPOSE_RELEASE="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
export PATH=$PATH:/usr/local/bin

# 检查 Python 是否存在
Check_python() {
  python_ver=$(python -h 2>/dev/null)
  if [[ -z ${python_ver} ]]; then
    echo -e "${Info} 没有安装Python，尝试使用Python3..."
    python3_ver=$(python3 -h 2>/dev/null)
    if [[ -z ${python3_ver} ]]; then
      echo -e "${Error} Python3 也未安装，无法继续！" && exit 1
    else
      echo -e "${Info} Python3 已安装，继续..."
      python="python3"
    fi
  else
    echo -e "${Info} Python 已安装，继续..."
    python="python"
  fi
}

install_soft() {
  (command -v yum >/dev/null 2>&1 && yum install "$@" -y) ||
    (command -v apt >/dev/null 2>&1 && apt install "$@" -y) ||
    (command -v pacman >/dev/null 2>&1 && pacman -Syu "$@") ||
    (command -v apt-get >/dev/null 2>&1 && apt-get install "$@" -y)

  if [[ $? != 0 ]]; then
    echo -e "${Red_font_prefix}安装基础软件失败，稍等会${Font_color_suffix}"
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
      echo -e "${Red_font_prefix}下载Docker失败${Font_color_suffix}"
      exit 1
    fi
    systemctl enable docker.service
    systemctl start docker.service
    echo -e "${Green_font_prefix}Docker${Font_color_suffix} 安装成功"
  else
    echo -e "${Green_font_prefix}Docker${Font_color_suffix} 已安装"

  fi
  command -v docker-compose >/dev/null 2>&1
  if [[ $? != 0 ]]; then
    echo -e "正在安装 Docker Compose"
    wget --no-check-certificate -O /usr/local/bin/docker-compose ${DOCKER_COMPOSE_RELEASE} >/dev/null 2>&1
    if [[ $? != 0 ]]; then
      echo -e "${Red_font_prefix}下载Compose失败${Font_color_suffix}"
      return 0
    fi
    chmod +x /usr/local/bin/docker-compose
    echo -e "${Green_font_prefix}Docker Compose${Font_color_suffix} 安装成功"
  else
    echo -e "${Green_font_prefix}Docker Compose${Font_color_suffix} 已安装"
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
      PORT=$(${python} -c 'import random;print(random.randint(10000, 65536))')
    fi
    create_docker_container "$PORT"
    number=$((number + 1))
  done
}

main
