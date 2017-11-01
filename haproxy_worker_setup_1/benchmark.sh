#!/usr/bin/env bash
set -eufo pipefail

function ensure_service_available() {
  local service_address="$1"
  for i in {1..120}; do 
    curl -s "${service_address}" >/dev/null && break || true
    sleep 1
  done
  curl -s "${service_address}" >/dev/null || { echo "service: ${service_address} did not respond in 2 minutes" >&2; exit 1;}
}

: ${grafan_host:="http://grafana:3000"}
: ${haproxy_host:="http://haproxy:80/"}

apk --no-cache add apache2-utils curl jq

echo "ensure grafana is running"
ensure_service_available "${grafan_host}"

echo "add datasources"
for file in $(find /grafana/datasources -type f) ; do
  echo "upload: ${file}"
  cat ${file} \
  | curl -s --user "admin:admin" \
    -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary "@-" \
    "${grafan_host}/api/datasources"
done
echo

echo "add dashboards"
for file in $(find /grafana/dashboards -type f) ; do
  echo "upload: ${file}"
  cat ${file} \
  | jq '{dashboard:.,overwrite:true}|.dashboard.id=null|.dashboard.version=null' \
  | curl -s --user "admin:admin" \
    -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary "@-" \
    "${grafan_host}/api/dashboards/db"
done
echo

echo "ensure haproxy is responding"
ensure_service_available "${haproxy_host}"

epoche_start="$(date +%s)"

echo "run apache benchmark"
ab -s 300 -n 100000 -c 50 "${haproxy_host}"
# ab -s 300 -n 1000 -k -c 5 "${haproxy_host}"

echo "final wait"
sleep 10

epoche_end="$(date +%s)"
second_duration="$(( $epoche_end - $epoche_start + 30 ))"

echo "render dashboard"
curl -s --user "admin:admin" \
  "${grafan_host}/render/dashboard/db/dashboard\
?orgId=1\
&from=now-${second_duration}s\
&to=now\
&kiosk\
&tz=CET\
&width=1200\
" \
  > /grafana_render/render_$(date +%FT%H_%M_%S).png

echo "finished"

