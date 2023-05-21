#!/bin/bash

key_define_refer() {
	# uci keys
	local custom_domain=''
	local text=""
	# tokens keys
	local TOKEN=''
	local CHAT_ID=''
}

notify_telegram() {
	local retry='--connect-timeout 3 --retry 3'
	curl $retry -sSL -o /dev/null -X POST \
		-H 'Content-Type: application/json' \
		-d '{"chat_id":"'"${CHAT_ID}"'","text":"'"${text}"'","parse_mode":"HTML","disable_notification":"false"}' \
		--url "https://${custom_domain:-api.telegram.org}/bot${TOKEN}/sendMessage"
}
