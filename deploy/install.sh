#!/bin/sh
set -eu
umask 077

repository_raw="https://raw.githubusercontent.com/qwernot/CM/main"
install_dir="${CMSINGBOX_INSTALL_DIR:-/opt/cmsingbox}"
data_dir="${CMSINGBOX_DATA_DIR:-/var/lib/cmsingbox}"
listen_port="${CMSINGBOX_PORT:-80}"
environment_file="/etc/cmsingbox.env"
service_file="/etc/systemd/system/cmsingbox.service"

# 升级时保留已安装实例的端口；新安装仍默认 80，显式环境变量优先。
if [ -z "${CMSINGBOX_PORT:-}" ] && [ -f "$service_file" ]; then
  previous_port="$(sed -n 's/.* -port \([0-9][0-9]*\).*/\1/p' "$service_file" | head -n 1)"
  case "$previous_port" in
    ''|*[!0-9]*) ;;
    *) if [ "$previous_port" -ge 1 ] && [ "$previous_port" -le 65535 ]; then listen_port="$previous_port"; fi ;;
  esac
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 运行，或在命令中加入 sudo。" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "缺少 curl，请先安装 curl。" >&2
  exit 1
fi
if ! command -v sha256sum >/dev/null 2>&1; then
  echo "缺少 sha256sum，请先安装 coreutils。" >&2
  exit 1
fi
if [ ! -c /dev/net/tun ]; then
  echo "提醒：未检测到 /dev/net/tun，TUN 不能直接启用；请确认宿主机内核支持。" >&2
fi
if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || true)" != 1 ]; then
  echo "提醒：IPv4 转发未开启；若作为局域网网关，请按预检说明开启。普通 HTTP/SOCKS 使用不受影响。" >&2
fi
if ! command -v systemctl >/dev/null 2>&1 || [ ! -d /run/systemd/system ]; then
  echo "此脚本需要使用 systemd 的 Linux 系统。Docker、RouterOS 请使用各自教程。" >&2
  exit 1
fi

# 透明代理需要 nftables 和策略路由。按发行版自动补齐，避免面板显示“当前环境缺少 nftables”。
if ! command -v nft >/dev/null 2>&1 || ! command -v ip >/dev/null 2>&1; then
  echo "正在安装透明代理所需的 nftables 和 iproute2..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nftables iproute2
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y nftables iproute
  elif command -v yum >/dev/null 2>&1; then
    yum install -y nftables iproute
  elif command -v zypper >/dev/null 2>&1; then
    zypper --non-interactive install nftables iproute2
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm nftables iproute2
  else
    echo "无法识别系统包管理器，请先手动安装 nftables 和 iproute2。" >&2
    exit 1
  fi
fi

case "$(uname -m)" in
  x86_64|amd64) architecture="amd64" ;;
  aarch64|arm64) architecture="arm64" ;;
  armv7l|armv7) architecture="arm" ;;
  *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac

temporary_binary="$(mktemp /tmp/cmsingbox.XXXXXX)"
temporary_kernel="$(mktemp /tmp/cmsingbox-kernel.XXXXXX)"
temporary_sums="$(mktemp /tmp/cmsingbox-sums.XXXXXX)"
trap 'rm -f "$temporary_binary" "$temporary_kernel" "$temporary_sums"' EXIT HUP INT TERM
echo "正在下载 CMSingBox 原生程序..."
release_version="$(curl --retry 5 -fsSL "${repository_raw}/bin/version.json" | sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([0-9][0-9]*\.[0-9][0-9]*\.[0-9]\)".*/\1/p')"
[ -n "$release_version" ] || { echo "无法读取有效版本号" >&2; exit 1; }
curl --retry 5 -fsSL "${repository_raw}/bin/releases/${release_version}/SHA256SUMS" -o "$temporary_sums"
manager_sha="$(awk -v name="cmsingbox-linux-${architecture}" '$2 == name {print $1}' "$temporary_sums")"
verify_file() {
  expected="$1"
  file="$2"
  [ "${#expected}" -eq 64 ] || { echo "缺少有效 SHA-256，取消安装" >&2; exit 1; }
  case "$expected" in *[!a-fA-F0-9]*) echo "无效 SHA-256" >&2; exit 1;; esac
  printf '%s  %s\n' "$expected" "$file" | sha256sum -c -
}
curl --retry 5 -fsSL "${repository_raw}/bin/releases/${release_version}/cmsingbox-linux-${architecture}" -o "$temporary_binary"
verify_file "$manager_sha" "$temporary_binary"
chmod 0755 "$temporary_binary"
if ! "$temporary_binary" -h >/dev/null 2>&1; then
  echo "下载的 CMSingBox 程序无法在当前机器运行。" >&2
  exit 1
fi

mkdir -p "$install_dir" "$data_dir"
if [ ! -x "$data_dir/bin/sing-box" ]; then
  echo "正在安装内置 sing-box 基础内核..."
  curl --retry 5 -fsSL "${repository_raw}/bin/sing-box-linux-${architecture}" -o "$temporary_kernel"
  case "$architecture" in
    amd64) kernel_sha=ddf3a5c6f7594b18992c1b374e1694d12fe0e3e37accef7b97c6f987dd7b7479 ;;
    arm64) kernel_sha=d5669c8c7f5ee0b3cbff72a5eb91c552e503b3e6f115b5fb5eface5896b7d317 ;;
    arm) kernel_sha=232ed3c5ef4e8d7ceae8e49b43e4111c7f86cc7efd79bfa5bd051ff085f0e00a ;;
  esac
  verify_file "$kernel_sha" "$temporary_kernel"
  mkdir -p "$data_dir/bin"
  install -m 0755 "$temporary_kernel" "$data_dir/bin/sing-box"
fi

backup_binary="$install_dir/cmsingbox.rollback"
backup_service="$install_dir/cmsingbox.service.rollback"
backup_environment="$install_dir/cmsingbox.env.rollback"
had_service=0
had_environment=0
[ ! -f "$service_file" ] || { cp -p "$service_file" "$backup_service"; had_service=1; }
[ ! -f "$environment_file" ] || { cp -p "$environment_file" "$backup_environment"; had_environment=1; }
had_previous=0
if [ -x "$install_dir/cmsingbox" ]; then
  cp -p "$install_dir/cmsingbox" "$backup_binary"
  had_previous=1
fi
rollback() {
  echo "新版本启动失败，正在回滚..." >&2
  systemctl stop cmsingbox.service 2>/dev/null || true
  if [ "$had_service" -eq 1 ]; then
    install -m 0644 "$backup_service" "$service_file"
  else
    rm -f "$service_file"
  fi
  if [ "$had_environment" -eq 1 ]; then
    install -m 0600 "$backup_environment" "$environment_file"
  else
    rm -f "$environment_file"
  fi
  systemctl daemon-reload
  if [ "$had_previous" -eq 1 ] && [ -f "$backup_binary" ]; then
    install -m 0755 "$backup_binary" "$install_dir/cmsingbox"
    systemctl restart cmsingbox.service || true
  else
    systemctl stop cmsingbox.service 2>/dev/null || true
  fi
  exit 1
}

systemctl stop cmsingbox.service 2>/dev/null || true
if ! install -m 0755 "$temporary_binary" "$install_dir/cmsingbox"; then
  rollback
fi

license_public_key="${CMSINGBOX_LICENSE_PUBLIC_KEY:-EwFgPIqxKUjPY45bIUHviX4fyZLAGoww6q5QJs9fKcE=}"
umask 077
if [ ! -f "$environment_file" ]; then
{
  printf 'CMSINGBOX_LICENSE_PUBLIC_KEY=%s\n' "$license_public_key"
} > "$environment_file"
fi

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
if ! systemctl daemon-reload || ! systemctl enable --now cmsingbox.service; then
  rollback
fi

healthy=0
attempt=0
while [ "$attempt" -lt 30 ]; do
  if curl --noproxy '*' -fsS "http://127.0.0.1:${listen_port}/" >/dev/null 2>&1; then
    healthy=1
    break
  fi
  attempt=$((attempt + 1))
  sleep 1
done
[ "$healthy" -eq 1 ] || rollback
rm -f "$backup_binary" "$backup_service" "$backup_environment"

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
echo "网关部署需额外检查 TUN、IPv4 转发与防火墙；不会自动修改宿主机的全局路由或清空防火墙。"
echo "检查命令: curl -fsSL ${repository_raw}/deploy/check-network.sh | sh -s -- native"
