#!/bin/bash

apt-get update
apt-get install -y tzdata supervisor build-essential tcl8.5 wget dnsutils
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
