#!/bin/sh
set -eu

repository_raw="https://raw.githubusercontent.com/qwernot/CM/main"
install_dir="${CMSINGBOX_INSTALL_DIR:-/opt/cmsingbox}"
data_dir="${CMSINGBOX_DATA_DIR:-/var/lib/cmsingbox}"
listen_port="${CMSINGBOX_PORT:-9092}"
environment_file="/etc/cmsingbox.env"
service_file="/etc/systemd/system/cmsingbox.service"

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 运行，或在命令中加入 sudo。" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "缺少 curl，请先安装 curl。" >&2
  exit 1
fi
if ! command -v systemctl >/dev/null 2>&1 || [ ! -d /run/systemd/system ]; then
  echo "此脚本需要使用 systemd 的 Linux 系统。Docker、RouterOS 请使用各自教程。" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64|amd64) architecture="amd64" ;;
  aarch64|arm64) architecture="arm64" ;;
  armv7l|armv7) architecture="arm" ;;
  *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac

temporary_binary="$(mktemp /tmp/cmsingbox.XXXXXX)"
trap 'rm -f "$temporary_binary"' EXIT HUP INT TERM
echo "正在下载 CMSingBox 原生程序..."
curl -fsSL "${repository_raw}/bin/cmsingbox-linux-${architecture}" -o "$temporary_binary"
chmod 0755 "$temporary_binary"

mkdir -p "$install_dir" "$data_dir"
systemctl stop cmsingbox.service 2>/dev/null || true
install -m 0755 "$temporary_binary" "$install_dir/cmsingbox"

license_public_key="${CMSINGBOX_LICENSE_PUBLIC_KEY:-tmySfFXNcgxWTfs5MLotrluSbEza8oDx9tSBkXoA4Dw=}"
umask 077
{
  printf 'CMSINGBOX_LICENSE_PUBLIC_KEY=%s\n' "$license_public_key"
} > "$environment_file"

{
  printf '%s\n' '[Unit]'
  printf '%s\n' 'Description=CMSingBox management service'
  printf '%s\n' 'After=network-online.target'
  printf '%s\n' 'Wants=network-online.target'
  printf '\n%s\n' '[Service]'
  printf '%s\n' 'Type=simple'
  printf '%s\n' 'User=root'
  printf '%s\n' 'Group=root'
  printf 'WorkingDirectory=%s\n' "$install_dir"
  printf 'EnvironmentFile=%s\n' "$environment_file"
  printf 'ExecStart=%s/cmsingbox -data %s -port %s\n' "$install_dir" "$data_dir" "$listen_port"
  printf '%s\n' 'Restart=always'
  printf '%s\n' 'RestartSec=5'
  printf '%s\n' 'LimitNOFILE=1048576'
  printf '\n%s\n' '[Install]'
  printf '%s\n' 'WantedBy=multi-user.target'
} > "$service_file"

chmod 0600 "$environment_file"
systemctl daemon-reload
systemctl enable --now cmsingbox.service

server_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
[ -n "$server_ip" ] || server_ip="服务器IP"
echo
echo "CMSingBox 原生服务已启动"
echo "管理地址: http://${server_ip}:${listen_port}"
echo "初始账号: admin"
echo "初始密码: admin"
echo "数据目录: ${data_dir}"
echo "日志命令: journalctl -u cmsingbox -f -n 100"
echo "注意：原生部署直接使用宿主机端口；若 53、2080 或后台端口冲突，请在后台修改对应端口。"
