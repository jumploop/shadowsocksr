FROM python:alpine

ENV TIMEOUT=300
ENV DNS_ADDR=8.8.8.8
ENV DNS_ADDR_2=8.8.4.4

ARG CONFIG_DIR=/etc/shadowsocksr
ARG CONFIG_USER_FILE=/etc/shadowsocksr/user-config.json
ARG BRANCH=manyuser
ARG WORK=/root

RUN mkdir -p $CONFIG_DIR \
    && cat >$CONFIG_USER_FILE <<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": ${SERVER_PORT},
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "password": "${PASSWORD}",
    "method": "${METHOD}",
    "protocol": "${PROTOCOL}",
    "protocol_param": "",
    "obfs": "${OBFS}",
    "obfs_param": "",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,

    "additional_ports" : {},
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
RUN apk --no-cache add -U libsodium wget unzip tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Shanghai/Asia" > /etc/timezone \
    && apk del tzdata

RUN mkdir -p $WORK  \
    && wget -q --no-check-certificate https://github.com/jumploop/shadowsocksr/archive/refs/heads/$BRANCH.zip -P $WORK  \
    && unzip $WORK/$BRANCH.zip -d $WORK \
    && rm -rf $WORK/*.zip

WORKDIR $WORK/shadowsocksr-$BRANCH/shadowsocks

RUN python3 fix_encrypt.py

EXPOSE $SERVER_PORT
CMD ["python3", "server.py", "-c", "$CONFIG_USER_FILE", "a"]
