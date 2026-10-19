#!/bin/bash
set -e

# Kiểm tra IP Wazuh Manager truyền vào
if [ -z "$1" ]; then
    echo "[!] LỖI: Vui lòng truyền IP Tailscale của Wazuh Manager!"
    echo "    Cú pháp: sudo bash install_telemetry.sh <IP_WAZUH_MANAGER>"
    exit 1
fi

WAZUH_MANAGER="$1"
TARGET_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$TARGET_USER")
HONEYPOT_DIR="$USER_HOME/kltn/edge-telemetry/honeypot"

echo "=================================================="
echo "[+] BẮT ĐẦU TỰ ĐỘNG HÓA TELEMETRY & HONEYPOT"
echo "    - Target Manager: $WAZUH_MANAGER"
echo "    - User: $TARGET_USER"
echo "=================================================="

# 1. CẬP NHẬT HỆ THỐNG & CÀI DOCKER, SURICATA
echo "[1/6] Cài đặt các gói phụ thuộc, Suricata và Docker..."
sudo apt-get update -y
sudo apt-get install -y curl gnupg apt-transport-https lsb-release jq suricata docker.io docker-compose-v2

sudo systemctl enable --now docker
sudo usermod -aG docker $TARGET_USER || true

# 2. CẤU HÌNH SURICATA IDS
echo "[2/6] Cấu hình Suricata..."
NET_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
sudo sed -i "s/interface: eth0/interface: $NET_IFACE/g" /etc/suricata/suricata.yaml
sudo suricata-update || true
sudo systemctl restart suricata

# 3. ĐỔI CỔNG SSH THẬT TỪ 22 SANG 22222 (NHƯỜNG PORT 22 CHO HONEYPOT)
echo "[3/6] Cấu hình đổi cổng SSH thật sang 22222..."
sudo sed -i 's/#Port 22/Port 22222/' /etc/ssh/sshd_config
sudo sed -i 's/Port 22/Port 22222/' /etc/ssh/sshd_config
sudo systemctl restart ssh || sudo systemctl restart sshd

# 4. TỰ ĐỘNG DỰNG COWRIE HONEYPOT BẰNG DOCKER COMPOSE
echo "[4/6] Khởi tạo và kích hoạt Cowrie Honeypot..."
mkdir -p "$HONEYPOT_DIR/cowrie-logs"
touch "$HONEYPOT_DIR/cowrie-logs/cowrie.json"

cat <<EOF > "$HONEYPOT_DIR/docker-compose.yml"
version: '3.8'
services:
  cowrie:
    image: cowrie/cowrie:latest
    container_name: cowrie_honeypot
    restart: always
    ports:
      - "22:2222"
      - "23:2223"
    volumes:
      - ./cowrie-logs:/cowrie/cowrie-git/var/log/cowrie
EOF

cd "$HONEYPOT_DIR"
sudo docker compose down 2>/dev/null || true
sudo docker compose up -d

# 5. CÀI ĐẶT WAZUH AGENT
echo "[5/6] Cài đặt Wazuh Agent..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --dearmor -o /usr/share/keyrings/wazuh-keyring.gpg --yes
echo "deb [signed-by=/usr/share/keyrings/wazuh-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt-get update -y
sudo apt-get install -y wazuh-agent

# 6. CẤU HÌNH WAZUH AGENT ĐỘC LOG SURICATA & COWRIE
echo "[6/6] Cấu hình ossec.conf để đọc eve.json và cowrie.json..."
OSSEC_CONF="/var/ossec/etc/ossec.conf"

# Trỏ IP Manager
sudo sed -i "s/<address>.*<\/address>/<address>$WAZUH_MANAGER<\/address>/" $OSSEC_CONF

# Chèn cấu hình đọc log Suricata (nếu chưa có)
if ! grep -q "/var/log/suricata/eve.json" $OSSEC_CONF; then
    sudo sed -i "/<\/ossec_config>/i \  <localfile>\n    <log_format>json<\/log_format>\n    <location>\/var\/log\/suricata\/eve.json<\/location>\n  <\/localfile>" $OSSEC_CONF
fi

# Chèn cấu hình đọc log Cowrie Honeypot (nếu chưa có)
COWRIE_JSON_PATH="$HONEYPOT_DIR/cowrie-logs/cowrie.json"
if ! grep -q "cowrie.json" $OSSEC_CONF; then
    sudo sed -i "/<\/ossec_config>/i \  <localfile>\n    <log_format>json<\/log_format>\n    <location>$COWRIE_JSON_PATH<\/location>\n  <\/localfile>" $OSSEC_CONF
fi

sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl restart wazuh-agent

echo "=================================================="
echo "[SUCCESS] HOÀN TẤT TỰ ĐỘNG HÓA!"
echo "1. SSH thật đã đổi sang Port: 22222"
echo "2. Port 22 & 23 hiện tại là BẪY HONEYPOT COWRIE"
echo "3. Log Suricata & Cowrie đã được đẩy về: $WAZUH_MANAGER"
echo "=================================================="