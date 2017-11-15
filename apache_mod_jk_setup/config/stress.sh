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

: ${haproxy_host:="http://haproxy:80"}

echo "ensure haproxy is responding"
ensure_service_available "${haproxy_host}"

: ${initial_wait:="10"}

echo "initial wait"
sleep ${initial_wait} 

#siege -d60 -t60m -c20 "${haproxy_path}"
#siege -t10s -c2 "${haproxy_path}"
: ${concurrent:="500"}
: ${delay:="60"}
: ${siege_path:="/hello/memory_usage?usage=5"}
: ${duration:="60H"}
siege -t${duration} -c${concurrent} -d${delay} "${haproxy_host}${siege_path}"


