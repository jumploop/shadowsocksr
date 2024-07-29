FROM python:alpine

ENV TIMEOUT=300
ENV DNS_ADDR=8.8.8.8
ENV DNS_ADDR_2=8.8.4.4

ARG CONFIG_DIR=/etc/shadowsocksr
ARG CONFIG_USER_FILE=/etc/shadowsocksr/user-config.json
ARG BRANCH=manyuser
ARG WORK=/root

RUN mkdir -p $CONFIG_DIR \
    && echo '{' >$CONFIG_USER_FILE\
    && echo '' >>$CONFIG_USER_FILE\
    && echo '"server": "0.0.0.0",'>>$CONFIG_USER_FILE\
    && echo '"server_ipv6": "::",'>>$CONFIG_USER_FILE\
    && echo '"server_port": ${SERVER_PORT},'>>$CONFIG_USER_FILE\
    && echo '"local_address": "127.0.0.1",'>>$CONFIG_USER_FILE\
    && echo '"local_port": 1080,'>>$CONFIG_USER_FILE\
    && echo '' >>$CONFIG_USER_FILE\
    && echo '"password": "${PASSWORD}",'>>$CONFIG_USER_FILE\
    && echo '"method": "${METHOD}",'>>$CONFIG_USER_FILE\
    && echo '"protocol": "${PROTOCOL}",'>>$CONFIG_USER_FILE\
    && echo '"protocol_param": "",'>>$CONFIG_USER_FILE\
    && echo '"obfs": "${OBFS}",'>>$CONFIG_USER_FILE\
    && echo '"obfs_param": "",'>>$CONFIG_USER_FILE\
    && echo '"speed_limit_per_con": 0,'>>$CONFIG_USER_FILE\
    && echo '"speed_limit_per_user": 0,'>>$CONFIG_USER_FILE\
    && echo '"additional_ports" : {},'>>$CONFIG_USER_FILE\
    && echo '"timeout": 120,'>>$CONFIG_USER_FILE\
    && echo '"udp_timeout": 60,'>>$CONFIG_USER_FILE\
    && echo '"dns_ipv6": false,'>>$CONFIG_USER_FILE\
    && echo '"connect_verbose_info": 0,'>>$CONFIG_USER_FILE\
    && echo '"redirect": "",'>>$CONFIG_USER_FILE\
    && echo '"fast_open": false'>>$CONFIG_USER_FILE\
    && echo '}' '>>$CONFIG_USER_FILE
}
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
