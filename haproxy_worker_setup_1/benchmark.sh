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

apk --no-cache add apache2-utils curl jq

# echo "initial wait"
# sleep 10
ensure_service_available "http://haproxy:80/"

echo "run apache benchmark"
ab -n 100 -c 10 http://haproxy:80/

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

echo "final wait"
sleep 10

echo "render dashboard"
curl -s --user "admin:admin" \
  "${grafan_host}/render/dashboard/db/dashboard?orgId=1&from=now-5m&to=now&kiosk&tz=CET&width=1200" \
  > /grafana_render/render_$(date +%FT%H_%M_%S).png

echo "finished"

