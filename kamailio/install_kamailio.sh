#!/bin/bash
set -e

echo "🔹 Updating system..."
apt update && apt upgrade -y

echo "🔹 Installing prerequisites..."
apt install -y software-properties-common curl gnupg2 lsb-release

echo "🔹 Adding Kamailio official repo..."
DISTRO=$(lsb_release -cs)
sh -c "echo 'deb http://deb.kamailio.org/kamailio $(lsb_release -cs) main' > /etc/apt/sources.list.d/kamailio.list"
sh -c "echo 'deb-src http://deb.kamailio.org/kamailio $(lsb_release -cs) main' >> /etc/apt/sources.list.d/kamailio.list"

echo "🔹 Adding Kamailio GPG key..."
curl -fsSL http://deb.kamailio.org/kamailiodebkey.gpg | gpg --dearmor -o /usr/share/keyrings/kamailio.gpg
echo "deb [signed-by=/usr/share/keyrings/kamailio.gpg] http://deb.kamailio.org/kamailio ${DISTRO} main" > /etc/apt/sources.list.d/kamailio.list

echo "🔹 Updating package index..."
apt update

echo "🔹 Installing Kamailio + utils + TLS..."
apt install -y kamailio kamailio-extra-modules kamailio-utils-modules kamailio-tls-modules kamailio-mysql-modules kamailio-postgres-modules

echo "🔹 Enabling Kamailio service..."
systemctl enable kamailio
systemctl start kamailio

echo "✅ Kamailio installation complete!"
echo "👉 Check version with: kamailio -V"
echo "👉 Default config: /etc/kamailio/kamailio.cfg"
echo "👉 Logs: journalctl -u kamailio -f"

