#!/bin/sh
time nice -n 20 sh build.sh --local $1 ${2:-192.168.3.2} 2>&1 | tee build.log
