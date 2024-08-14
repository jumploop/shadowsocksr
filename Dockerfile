FROM python:alpine

ENV TIMEOUT=300
ENV DNS_ADDR=8.8.8.8
ENV DNS_ADDR_2=8.8.4.4

ARG CONFIG_DIR=/etc/shadowsocksr
ARG CONFIG_USER_FILE=/etc/shadowsocksr/user-config.json
ARG BRANCH=manyuser
ARG WORK=/root

RUN mkdir -p $CONFIG_DIR
COPY ./user-config.json   $CONFIG_DIR

RUN apk --no-cache add -U libsodium wget unzip tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Shanghai/Asia" > /etc/timezone \
    && apk del tzdata

RUN mkdir -p $WORK  \
    && wget -q --no-check-certificate https://github.com/jumploop/shadowsocksr/archive/refs/heads/$BRANCH.zip -P $WORK  \
    && unzip $WORK/$BRANCH.zip -d $WORK \
    && rm -rf $WORK/*.zip \
    && ln -sf /dev/null /var/log/ssserver.log

WORKDIR $WORK/shadowsocksr-$BRANCH/shadowsocks

RUN python3 fix_encrypt.py

EXPOSE $SERVER_PORT
CMD ["python3", "server.py", "-c", "/etc/shadowsocksr/user-config.json", "a"]
