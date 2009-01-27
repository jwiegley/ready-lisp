#!/bin/sh
time nice -n 20 sh build.sh --local $1 ${2:-192.168.2.114} 2>&1 | tee build.log
