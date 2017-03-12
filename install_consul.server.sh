#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
#set -e
apt-get -qq update
apt-get -qq install unzip -y

wget --quiet https://releases.hashicorp.com/consul/0.7.4/consul_0.7.4_linux_amd64.zip  -P /opt/
mkdir -p /opt/consul /opt/consul/datacenter /etc/consul.d

unzip -q -o /opt/consul_*.zip   -d /opt/consul

ln -s /opt/consul/consul /usr/sbin/consul

cat <<EOF >> /etc/hosts
192.168.30.10 consul-001.vagrant
192.168.30.20 consul-002.vagrant
192.168.30.30 consul-003.vagrant
EOF

cat <<EOF > /etc/systemd/system/consul.service
  [Unit]
  Description=HashiCorp's consul
  After=network-online.target

  [Service]
  Type=simple
  PIDFile=/var/run/consul/consul-server.pid
  ExecStart=/opt/consul/consul agent -ui -log-level info -data-dir=/opt/consul/datacenter --config-dir /etc/consul.d -bind="$(ip address show enp0s8 | grep 'inet 192.168.30' | awk '{print $2}' | awk -F"/" '{print $1}')" -advertise="$(ip address show enp0s8 | grep 'inet 192.168.30' | awk '{print $2}' | awk -F"/" '{print $1}')"
  Restart=on-failure
  ExecReload=/bin/kill -HUP
  KillSignal=SIGTERM

  [Install]
  WantedBy=multi-user.target
EOF

cat  <<EOF > /etc/consul.d/consul.json
{
  "advertise_addr": "$(ip address show enp0s8 | grep 'inet 192.168.30' | awk '{print $2}' | awk -F"/" '{print $1}')",
  "datacenter": "vagrant_DC",
  "bootstrap_expect": 3,
  "data_dir": "/opt/consul",
  "leave_on_terminate": true,
  "log_level": "INFO",
  "enable_syslog": true,
  "node_name": "$(hostname -f)",
  "server": true,
  "addresses": {
    "http": "0.0.0.0"
  },
  "ports": {
    "http": 8080
  },
  "telemetry": {
     "statsite_address": "127.0.0.1:8125"
  },
  "rejoin_after_leave": false,
  "start_join": [
    "consul-001.vagrant",
    "consul-002.vagrant",
    "consul-003.vagrant"
  ],
  "client_addr": "0.0.0.0"
}
EOF

systemctl enable consul
systemctl daemon-reload


systemctl start consul
