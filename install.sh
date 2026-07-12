#!/bin/bash

# arguments

SECRET_KEY=""
NODE_PORT=2222
APPLY_SYSCTL=false
TG_PORTS=""
NP_IPS=""

while [ $# -gt 0 ]; do
  case $1 in
    --sk) SECRET_KEY=$2; shift 2 ;;
    --p)  NODE_PORT=$2; shift 2 ;;
    --s)  APPLY_SYSCTL=true; shift ;;
    --tg) TG_PORTS=$2; shift 2 ;;
    --np) NP_IPS=$2; shift 2 ;;
    *)    shift ;;
  esac
done

[ -z "$SECRET_KEY" ] && exit 1

REBOOT=false

# deps

apt-get update
apt-get install -y gpg

# install docker

command -v docker &>/dev/null || curl -fsSL https://get.docker.com | sh

# install ufw

command -v ufw &>/dev/null || apt-get install -y ufw

# xanmod kernel (bbrv3)

if [ "$APPLY_SYSCTL" = true ] && [ "$(uname -m)" = "x86_64" ] && ! systemd-detect-virt -c &>/dev/null; then
  CODENAME=$(. /etc/os-release; echo "$VERSION_CODENAME")
  curl -fsSL https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $CODENAME main" > /etc/apt/sources.list.d/xanmod-release.list
  apt-get update
  apt-get install -y linux-xanmod-x64v3 \
    || apt-get install -y linux-xanmod-lts-x64v3 \
    || apt-get install -y linux-xanmod-x64v2 \
    || apt-get install -y linux-xanmod-lts-x64v2 \
    || apt-get install -y linux-xanmod-x64v1 \
    || apt-get install -y linux-xanmod-lts-x64v1
  dpkg -l | grep -q linux-xanmod && REBOOT=true
fi

# sysctl

if [ "$APPLY_SYSCTL" = true ]; then
  modprobe nf_conntrack 2>/dev/null
  cat <<EOF >> /etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_ecn = 2
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.netfilter.nf_conntrack_max = 1048576
EOF
  sysctl -p
fi

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

# ufw

{ [ -n "$TG_PORTS" ] || [ -n "$NP_IPS" ]; } && { ufw limit OpenSSH; ufw --force enable; }

# trafficguard

if [ -n "$TG_PORTS" ]; then
  curl -fsSL https://raw.githubusercontent.com/dotX12/traffic-guard/master/install.sh | bash
  [ -z "$NP_IPS" ] && _tg_all="$TG_PORTS:$NODE_PORT" || _tg_all="$TG_PORTS"
  IFS=':' read -ra _ports <<< "$_tg_all"
  for _p in "${_ports[@]}"; do ufw allow "$_p/tcp"; done
  traffic-guard full \
    -u https://raw.githubusercontent.com/shadow-netlab/traffic-guard-lists/refs/heads/main/public/antiscanner.list \
    -u https://raw.githubusercontent.com/shadow-netlab/traffic-guard-lists/refs/heads/main/public/government_networks.list \
    -u https://raw.githubusercontent.com/shadow-netlab/traffic-guard-lists/refs/heads/main/public/skipa.list \
    --enable-logging
fi

# nodeprotect

if [ -n "$NP_IPS" ]; then
  IFS=':' read -ra _ips <<< "$NP_IPS"
  for _ip in "${_ips[@]}"; do ufw allow from "$_ip" to any port "$NODE_PORT" proto tcp; done
  ufw deny "$NODE_PORT/tcp"
fi

# start

docker compose up -d

# reboot

if [ "$REBOOT" = true ]; then
  reboot
else
  docker compose logs -f -t
fi
