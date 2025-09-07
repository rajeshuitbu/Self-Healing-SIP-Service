#!/bin/bash
set -e

# 1. Update system
apt update && apt upgrade -y

# 2. Install dependencies
apt install -y wget curl tar

# 3. Create Prometheus user & directories
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus

# 4. Download latest Prometheus
PROM_VERSION="2.54.1"   # Latest stable (Aug 2025)
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

# 5. Move binaries
cp prometheus promtool /usr/local/bin/

# 6. Move config & consoles
cp -r consoles/ console_libraries/ /etc/prometheus/
cp prometheus.yml /etc/prometheus/prometheus.yml

# 7. Set ownership
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# 8. Create systemd service
cat <<EOF >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 9. Reload systemd & start Prometheus
systemctl daemon-reexec
systemctl enable prometheus
systemctl start prometheus

echo "✅ Prometheus installed and running on port 9090"
echo "👉 Open http://<your-server-ip>:9090 to access the UI"

