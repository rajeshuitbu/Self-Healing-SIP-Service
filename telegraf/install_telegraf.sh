#!/bin/bash
set -e

echo "🔹 Installing Telegraf..."

# 1. Add InfluxData GPG key
wget -q https://repos.influxdata.com/influxdata-archive.key
gpg --dearmor < influxdata-archive.key | tee /usr/share/keyrings/influxdata-archive.gpg > /dev/null

# 2. Add Telegraf repository
echo "deb [signed-by=/usr/share/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" \
    | tee /etc/apt/sources.list.d/influxdata.list

# 3. Update and install
apt update && apt install -y telegraf

# 4. Enable and start service
systemctl enable telegraf
systemctl start telegraf

echo "✅ Telegraf installed and running!"
echo "👉 Config file: /etc/telegraf/telegraf.conf"

