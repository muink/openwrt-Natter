#!/bin/sh
#
# Author: muink
# Github: https://github.com/muink/luci-app-natter
#
[ "$1" == "0" ] && port= || port="$1"
[ -n "$2" ] && output="> $2"

#/etc/init.d/firewall reload >/dev/null 2>&1

natter --check-nat $port >/dev/null 2>&1
eval "natter --check-nat $port 2>&1 | sed -En \"/(UDP|TCP): \[/{s,.+(UDP|TCP): \[(.+)\]\$,\1:\2,g p}\" $output"
