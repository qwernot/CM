#!/bin/sh
set -eu

repository_raw="https://raw.githubusercontent.com/qwernot/CM/main"
install_dir="${CMSINGBOX_DOCKER_INSTALL_DIR:-/opt/cmsingbox-docker}"
container_ip="${CMSINGBOX_IP:-}"

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 运行，或在命令中加入 sudo。" >&2
  exit 1
fi
if [ -z "$container_ip" ]; then
  echo "必须设置 CMSINGBOX_IP，它应是局域网内、DHCP 地址池外的空闲 IP。" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "缺少 curl，请先安装 curl。" >&2
  exit 1
fi
if ! command -v ip >/dev/null 2>&1; then
  echo "缺少 iproute2，无法自动识别网络。" >&2
  exit 1
fi
if ! command -v docker >/dev/null 2>&1; then
  echo "未检测到 Docker，正在安装 Docker Engine..."
  curl -fsSL https://get.docker.com | sh
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "需要 Docker Compose v2 插件。" >&2
  exit 1
fi

parent="${CMSINGBOX_PARENT:-$(ip -4 route show default | awk 'NR==1 {for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')}"
gateway="${CMSINGBOX_GATEWAY:-192.168.1.1}"
subnet="${CMSINGBOX_SUBNET:-$(ip -4 route show dev "$parent" scope link | awk '$1 ~ /^[0-9]+\./ && $1 ~ /\// {print $1; exit}')}"

if [ -z "$parent" ] || [ -z "$gateway" ] || [ -z "$subnet" ]; then
  echo "自动识别网络失败，请设置 CMSINGBOX_PARENT、CMSINGBOX_GATEWAY 和 CMSINGBOX_SUBNET。" >&2
  exit 1
fi
if ip -4 addr show dev "$parent" | grep -q "inet ${container_ip}/"; then
  echo "CMSINGBOX_IP 不能与宿主机 IP 相同。" >&2
  exit 1
fi
if [ "$container_ip" = "$gateway" ]; then
  echo "CMSINGBOX_IP 不能与网关 IP 相同。" >&2
  exit 1
fi
if command -v ping >/dev/null 2>&1 && ping -c 1 -W 1 "$container_ip" >/dev/null 2>&1; then
  echo "地址 ${container_ip} 已有设备响应，请换一个空闲 IP。" >&2
  exit 1
fi

network_name=""
for network_id in $(docker network ls -q); do
  network_driver="$(docker network inspect "$network_id" --format '{{.Driver}}')"
  network_subnet="$(docker network inspect "$network_id" --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}')"
  network_gateway="$(docker network inspect "$network_id" --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}')"
  network_parent="$(docker network inspect "$network_id" --format '{{index .Options "parent"}}')"
  if [ "$network_driver" = "macvlan" ] && [ "$network_subnet" = "$subnet" ] && [ "$network_parent" = "$parent" ]; then
    network_name="$(docker network inspect "$network_id" --format '{{.Name}}')"
    if [ -n "$network_gateway" ] && [ "$network_gateway" != "$gateway" ]; then
      echo "已有 macvlan 网络 ${network_name} 的网关为 ${network_gateway}，将按该网络配置复用。"
      gateway="$network_gateway"
    fi
    break
  fi
done
if [ -z "$network_name" ]; then
  network_name="${CMSINGBOX_DOCKER_NETWORK:-cmsingbox_lan}"
  if docker network inspect "$network_name" >/dev/null 2>&1; then
    echo "Docker 网络 ${network_name} 已存在但参数不兼容，请通过 CMSINGBOX_DOCKER_NETWORK 指定新名称。" >&2
    exit 1
  fi
  docker network create --driver macvlan --subnet "$subnet" --gateway "$gateway" --opt "parent=${parent}" "$network_name" >/dev/null
else
  echo "复用已有 macvlan 网络: ${network_name}"
fi

mkdir -p "$install_dir/data"
curl --retry 5 -fsSL "${repository_raw}/deploy/docker-compose.auto.yml" -o "$install_dir/docker-compose.yml"

container_image="${CMSINGBOX_IMAGE:-darkver8/cmsingbox:latest}"
umask 077
{
  printf 'CMSINGBOX_IP=%s\n' "$container_ip"
  printf 'CMSINGBOX_PARENT=%s\n' "$parent"
  printf 'CMSINGBOX_SUBNET=%s\n' "$subnet"
  printf 'CMSINGBOX_GATEWAY=%s\n' "$gateway"
  printf 'CMSINGBOX_DOCKER_NETWORK=%s\n' "$network_name"
  printf 'CMSINGBOX_IMAGE=%s\n' "$container_image"
} > "$install_dir/.env"

cd "$install_dir"
docker compose pull
docker compose up -d

echo
echo "CMSingBox Docker 容器已启动"
echo "管理地址: http://${container_ip}:9092"
echo "HTTP/SOCKS5: ${container_ip}:2080"
echo "初始账号: admin"
echo "初始密码: admin"
echo "首次登录后请立即修改密码，并在设置中开启允许局域网访问。"
echo "日志命令: cd ${install_dir} && docker compose logs -f --tail=100"
