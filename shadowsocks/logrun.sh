#!/bin/bash
if [ -f "/usr/local/shadowsocksr/user-config.json" ]; then
  CONF="/usr/local/shadowsocksr/user-config.json"
elif [ -f "/etc/shadowsocksr/user-config.json" ]; then
  CONF="/etc/shadowsocksr/user-config.json"
fi
cd "$(dirname "$0")" || exit
eval "$(ps -ef | grep "[0-9] python server\\.py a" | awk '{print "kill "$2}')"
ulimit -n 512000
nohup python server.py -c "${CONF}" a >>/var/log/ssserver.log 2>&1 &
