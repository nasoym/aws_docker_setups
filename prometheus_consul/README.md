
docker run -d -P -e "SERVICE_TAGS=monitoring" nginx
  docker run -d --name=consul -p 8500:8500 gliderlabs/consul-server -bootstrap
  docker run -d --name=registrator --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator consul://172.31.23.189:8500
  docker run -d --name=bla -P -e "SERVICE_TAGS=monitoring" redis

