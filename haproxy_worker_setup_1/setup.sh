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

: ${grafan_host:="http://localhost:3000"}

ensure_service_available "${grafan_host}"

echo "add datasources"
for file in $(find ./config/datasources -type f) ; do
  echo "upload: ${file}"
  cat ${file} \
  | curl -s --user "admin:admin" \
    -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary "@-" \
    "${grafan_host}/api/datasources"
done
echo

echo "add dashboards"
for file in $(find ./config/dashboards -type f) ; do
  echo "upload: ${file}"
  cat ${file} \
  | curl -s --user "admin:admin" \
    -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary "@-" \
    "${grafan_host}/api/dashboards/db"
done
echo
