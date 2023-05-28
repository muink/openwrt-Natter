#!/bin/bash
#
# depends: jsonfilter

key_define_refer() {
	# uci keys
	local outter_ip=''
	local outter_port=''
	local fqdn=''
	local a_record=''
	local srv_record=''
	local srv_service=''
	local srv_proto=''
	local srv_target=''
	# tokens keys
	TOKEN=''
	ZONE_ID=''
	SRV_PRIORITY='' # Optional: 0 - 65535
	SRV_WEIGHT='' # Optional: 0 - 65535
}

# http_request <data> [record_id]
http_request() {
	local data="$1"
	local id="$2"
	local method
	[ -z "${id}" ] && method=POST || method=PUT # or PATCH

	curl $retry -sSL -o /dev/null -X ${method} \
		--url "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${id}" \
		-H "Authorization: Bearer ${TOKEN}" \
		-H 'Content-Type: application/json' \
		-d "$data"
}

ddns_cloudflare() {
	local retry='--connect-timeout 3 --retry 3'
#curl $retry -sSL -X GET \
#	--url "https://api.cloudflare.com/client/v4/user/tokens/verify" \
#	-H "Authorization: Bearer ${TOKEN}" \
#	-H "Content-Type:application/json" | jq
#curl $retry -sSL -X GET \
#	--url "https://api.cloudflare.com/client/v4/zones" \
#	-H "Authorization: Bearer ${TOKEN}" \
#	-H "Content-Type:application/json" | jq
	local records="$(curl $retry -sSL -X GET \
		--url "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
		-H "Authorization: Bearer ${TOKEN}" \
		-H 'Content-Type: application/json')"
	[ -z "$records" -o -n "$(echo "$records"|grep -E "\"success\":\s*false")" ] && return 1

	local data the_record

	if [ "$a_record" == "1" ]; then
		data="{ \
			\"type\": \"A\", \
			\"name\": \"${fqdn}\", \
			\"content\": \"${outter_ip}\", \
			\"ttl\": 1, \
			\"proxied\": false \
		}"
		the_record="$(jsonfilter -s "$records" -qe '@.result[*]'|grep "\"type\": \"A\""|grep "\"name\": \"${fqdn}\"")"
		http_request "$data" "$(jsonfilter -s "$the_record" -qe '@.id')"
	fi

	if [ "$srv_record" == "1" ]; then
		data="{ \
			\"type\": \"SRV\", \
			\"data\": { \
				\"service\": \"_${srv_service}\", \
				\"proto\": \"_${srv_proto}\", \
				\"name\": \"${fqdn}\", \
				\"priority\": ${SRV_PRIORITY:-1}, \
				\"weight\": ${SRV_WEIGHT:-1}, \
				\"port\": ${outter_port}, \
				\"target\": \"${srv_target}\" \
			}, \
			\"ttl\": 1, \
			\"proxied\": false \
		}"
		the_record="$(jsonfilter -s "$records" -qe '@.result[*]'|grep "\"type\": \"SRV\""|grep "\"name\": \"_${srv_service}._${srv_proto}.${fqdn}\""|grep "\"priority\": ${SRV_PRIORITY:-1}"|grep "\"weight\": ${SRV_WEIGHT:-1}")"
		http_request "$data" "$(jsonfilter -s "$the_record" -qe '@.id')"
	fi
}
