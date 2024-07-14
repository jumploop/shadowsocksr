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


RUN apk --no-cache add python3 \
    libsodium \
    wget unzip

RUN apk add -U tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Shanghai/Asia" > /etc/timezone && apk del tzdata

RUN mkdir -p $WORK && \
    wget -q --no-check-certificate https://github.com/jumploop/shadowsocksr/archive/$BRANCH.zip -P $WORK && \
    cd $WORK && unzip $BRANCH.zip


WORKDIR $WORK/shadowsocksr-$BRANCH/shadowsocks


EXPOSE $SERVER_PORT
CMD python3 server.py -p $SERVER_PORT -k $PASSWORD -m $METHOD -O $PROTOCOL -o $OBFS
