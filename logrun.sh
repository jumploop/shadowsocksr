#!/bin/bash
cd "$(dirname "$0")" || exit
#python_ver=$(ls /usr/bin|grep -e "^python[23]\.[1-9]\+$"|tail -1)
eval "$(ps -ef | grep "[0-9] python server\\.py m" | awk '{print "kill "$2}')"
ulimit -n 512000
nohup python server.py m >> ssserver.log 2>&1 &

