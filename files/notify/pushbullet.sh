#!/bin/bash

key_define_refer() {
	# uci keys
	local custom_domain=''
	local text=""
	# tokens keys
	local TOKEN=''
	local TITLE=''
}

notify_pushbullet() {
	local retry='--connect-timeout 5 --retry 3'
	curl $retry -sSL -o /dev/null -X POST \
		-H "Access-Token: ${TOKEN}" \
		-H 'Content-Type: application/json' \
		-d '{"type":"note","body":"'"${text}"'","title":"'"${TITLE}"'"}' \
		--url "https://${custom_domain:-api.pushbullet.com}/v2/pushes"
}
