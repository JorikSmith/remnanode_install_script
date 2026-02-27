#!/bin/bash
# arguments
SECRET_KEY=""
NODE_PORT=2222
APPLY_SYSCTL=false

while [ $# -gt 0 ]; do
    case $1 in
        --sk) SECRET_KEY=$2; shift 2 ;;
        --p)  NODE_PORT=$2; shift 2 ;;
        --s)  APPLY_SYSCTL=true; shift ;;
        *) shift ;;
    esac
done

[ -z "$SECRET_KEY" ] && exit 1

# sysctl
if [ "$APPLY_SYSCTL" = true ]; then
    cat <<EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

    sysctl -p
fi

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
    cap_add:
      - NET_ADMIN
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
