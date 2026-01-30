#!/bin/bash

#arguments
SECRET_KEY=""
NODE_PORT=2222

while [ $# -gt 0 ]; do
    case $1 in
        --sk) SECRET_KEY=$2; shift 2 ;;
        --p)  NODE_PORT=$2; shift 2 ;;
    esac
    shift
done

[ -z "$SECRET_KEY" ] && exit 1

# install docker
sudo curl -fsSL https://get.docker.com | sh

# directory
mkdir -p /opt/remnanode && cd /opt/remnanode

# docker compose
cat <<EOF > docker-compose.yml
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:latest
    network_mode: host
    restart: always
    ulimits:
      nofile:
        soft: 1048576
        hard: 1048576
    environment:
      - NODE_PORT=$NODE_PORT
      - SECRET_KEY=$SECRET_KEY
EOF

# start
docker compose up -d && docker compose logs -f -t