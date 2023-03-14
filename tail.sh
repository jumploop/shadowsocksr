#!/bin/bash
cd "$(dirname "$0")" || exit
tail -f ssserver.log
