#!/bin/bash
# Copyright (C) 2023 muink
#
protocol=$1
inner_ip=$2
inner_port=$3
outter_ip=$4
outter_port=$5

. "${IPKG_INSTROOT}/lib/functions.sh"
. "${IPKG_INSTROOT}/lib/functions/procd.sh"

# plugins
ETCPATH='/etc/natter'
DEFAULT_TEXT="Natter: [${protocol^^}] ${inner_ip}:${inner_port} -> ${outter_ip}:${outter_port}"
# uci
CONFIG_NAME='natter-plugins'
NOTIFY='notify'

config_load "$CONFIG_NAME"


validate_section_notify() {
	uci_load_validate $CONFIG_NAME $NOTIFY "$1" "$2" \
		'enabled:bool:0' \
		'comment:uciname' \
		'script:string' \
		'tokens:list(string)' \
		'custom_domain:hostname' \
		'text:string'
}

process_notify() {
	[ "$2" == "0" ] || { >&2 echo "$(basename $0): section $1 validation failed"; return 1; }
	[ "$enabled" == "0" ] && return 0
	[ -z "$script" -o -z "$tokens" ] && return 1

	local path="$ETCPATH/notify"	
	[ -f "$path/${script}" ] || return 1

	[ -n "$text" ] && eval "text=\"$text\"" || text="$DEFAULT_TEXT"
	echo "notify_${script%.*}: $text"
	. "$path/${script}"
	eval "$tokens"
	eval "notify_${script%.*}"
}


config_foreach validate_section_notify "$NOTIFY" process_notify || return $?
