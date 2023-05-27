#!/bin/bash
# Copyright (C) 2023 muink
#
protocol=$1
inner_ip=$2
inner_port=$3
outter_ip=$4
outter_port=$5
ifname=$(ip -4 -o addr|grep "$inner_ip"|cut -f2 -d' '); [ -z "$ifname" ] && return 0

. "${IPKG_INSTROOT}/lib/functions.sh"
. "${IPKG_INSTROOT}/lib/functions/procd.sh"

# plugins
ETCPATH='/etc/natter'
DEFAULT_TEXT="Natter: [${protocol^^}] ${inner_ip}:${inner_port} -> ${outter_ip}:${outter_port}"
# uci
CONFIG_NAME='natter'
CONFIG_PLUG_NAME='natter-plugins'
PORTRULES='portrule'
NOTIFY='notify'
DDNS='ddns'

config_load "$CONFIG_PLUG_NAME"


validate_section_notify() {
	uci_load_validate $CONFIG_PLUG_NAME $NOTIFY "$1" "$2" \
		'enabled:bool:0' \
		'comment:uciname' \
		'script:string' \
		'tokens:list(string)' \
		'custom_domain:hostname' \
		'text:string'
}

validate_section_ddns() {
	uci_load_validate $CONFIG_PLUG_NAME $DDNS "$1" "$2" \
		'enabled:bool:0' \
		'comment:uciname' \
		'script:string' \
		'tokens:list(string)' \
		'bind_port:range(1, 65535)' \
		'proto:or("udp", "tcp"):tcp' \
		'fqdn:hostname' \
		'a_record:bool:0' \
		'srv_record:bool:0' \
		'srv_service:string' \
		'srv_proto:or("udp", "tcp", "tls"):tcp' \
		'srv_target:hostname'
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
	key_define_refer
	eval "$tokens"
	eval "notify_${script%.*}"
}

process_ddns() {
	[ "$2" == "0" ] || { >&2 echo "$(basename $0): section $1 validation failed"; return 1; }
	[ "$enabled" == "0" ] && return 0
	[ -z "$script" -o -z "$tokens" -o -z "$bind_port" -o -z "$fqdn" ] && return 1
	[ "$a_record" == "0" -a "$srv_record" == "0" ] && return 1
	[ "$srv_record" == "1" -a -z "$srv_service" ] && return 1

	[ "$bind_port" == "$inner_port" ] || return 1
	[ "$proto" == "$protocol" ] || return 1
	local bind_ifname
	for i in $(uci -q show $CONFIG_NAME|grep "^$CONFIG_NAME\.@$PORTRULES"|grep "\.bind_port='$bind_port'$"|sed -En "s|^.+@$PORTRULES\[(\d+)\].*|\1|p"); do
		[ "$(uci -q get $CONFIG_NAME.@$PORTRULES[$i].enabled)" == "0" ] && continue
		[ -n "$(uci -q get $CONFIG_NAME.@$PORTRULES[$i].proto|grep -E "both|$proto")" ] || continue
		bind_ifname="$(uci -q get $CONFIG_NAME.@$PORTRULES[$i].bind_ifname)" && break
	done
	[ -n "$bind_ifname" -a "$bind_ifname" != "$ifname" ] && return 1

	local path="$ETCPATH/ddns"
	[ -f "$path/${script}" ] || return 1

	[ -z "$srv_target" ] && srv_target="$fqdn"
	[ "$a_record" == "1" ] && echo "${fqdn} -> ${outter_ip}"
	[ "$srv_record" == "1" ] && echo "_${srv_service}._${srv_proto}.${fqdn} -> ${srv_target}:${outter_port}"
	. "$path/${script}"
	key_define_refer
	eval "$tokens"
	eval "ddns_${script%.*}"
}


config_foreach validate_section_notify "$NOTIFY" process_notify
config_foreach validate_section_ddns "$DDNS" process_ddns
