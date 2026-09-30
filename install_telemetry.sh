#!/bin/bash
# Cú pháp: sudo bash install_telemetry.sh <IP_WAZUH_MANAGER>

# Dừng script ngay nếu có lỗi nghiêm trọng
set -e

WAZUH_MANAGER_IP=$1

if [ -z "$WAZUH_MANAGER_IP" ]; then
  echo "[!] LỖI: Thiếu IP của Wazuh Manager!"
  echo "Cú pháp: sudo bash install_telemetry.sh <IP_WAZUH_MANAGER>"
  exit 1
fi

# Chuyển APT sang chế độ không hỏi giao diện (Non-interactive)
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo "[+] 1. CÀI ĐẶT TIỀN ĐỀ & SURICATA IDS"
echo "=========================================="
sudo apt-get update -y
sudo apt-get install -y curl gnupg apt-transport-https lsb-release jq suricata

echo "[+] Khởi tạo bộ Rules ban đầu cho Suricata..."
sudo suricata-update || true
NET_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
sudo sed -i "s/interface: eth0/interface: $NET_IFACE/g" /etc/suricata/suricata.yaml
echo "[+] Đã cập nhật card mạng Suricata lắng nghe trên: $NET_IFACE"
sudo systemctl enable suricata

echo "=========================================="
echo "[+] 2. TỰ ĐỘNG THÊM REPO & CÀI WAZUH AGENT"
echo "=========================================="
# Tải và cài GPG Key của Wazuh
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/wazuh.gpg --import
sudo chmod 644 /etc/apt/trusted.gpg.d/wazuh.gpg

# Thêm Repository
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

# Cập nhật và cài đặt Agent với IP được truyền vào
sudo apt-get update -y
WAZUH_MANAGER="$WAZUH_MANAGER_IP" sudo -E apt-get install -y wazuh-agent

echo "=========================================="
echo "[+] 3. CẤU HÌNH ĐỔ LOG SURICATA VỀ WAZUH AGENT"
echo "=========================================="
OSSEC_CONF="/var/ossec/etc/ossec.conf"

if [ -f "$OSSEC_CONF" ]; then
  # Đảm bảo IP Manager luôn chính xác
  sudo sed -i "s/<address>.*<\/address>/<address>$WAZUH_MANAGER_IP<\/address>/g" "$OSSEC_CONF"

  # Nhúng file log eve.json của Suricata vào ossec.conf
  if ! grep -q "/var/log/suricata/eve.json" "$OSSEC_CONF"; then
    sudo sed -i '/<\/ossec_config>/i \
  <localfile>\n    <log_format>json<\/log_format>\n    <location>\/var\/log\/suricata\/eve.json<\/location>\n  <\/localfile>' "$OSSEC_CONF"
    echo "[+] Đã tích hợp /var/log/suricata/eve.json vào ossec.conf"
  fi
else
  echo "[!] LỖI RẤT NGHỆM TRỌNG: Wazuh Agent chưa được cài đúng nên không thấy ossec.conf!"
  exit 1
fi

echo "=========================================="
echo "[+] 4. KÍCH HOẠT VÀ KHỞI ĐỘNG DỊCH VỤ"
echo "=========================================="
sudo systemctl daemon-reload
sudo systemctl restart suricata
sudo systemctl enable --now wazuh-agent
sudo systemctl restart wazuh-agent

echo ""
echo "=================================================="
echo "[SUCCESS] HOÀN TẤT SETUP TELEMETRY TRÊN MÁY SẠCH!"
echo "Wazuh Agent đang kết nối tới Manager: $WAZUH_MANAGER_IP"
echo "=================================================="