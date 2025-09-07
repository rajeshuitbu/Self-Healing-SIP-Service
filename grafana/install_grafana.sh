#!/bin/bash
set -e

# 1. Update system
apt update && apt upgrade -y

# 2. Install dependencies
apt install -y wget apt-transport-https software-properties-common

# 3. Add Grafana GPG key
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor -o /usr/share/keyrings/grafana.gpg

# 4. Add Grafana APT repo
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# 5. Install Grafana OSS (open-source edition)
apt update && apt install -y grafana

# 6. Enable and start Grafana
systemctl daemon-reexec
systemctl enable grafana-server
systemctl start grafana-server

echo "✅ Grafana installed and running!"
echo "👉 Open http://<your-server-ip>:3000"
echo "Default login: admin / admin"

