#!/bin/sh
set -eu

repository_raw="https://raw.githubusercontent.com/qwernot/CM/main"
install_dir="${CMSINGBOX_LICENSE_INSTALL_DIR:-/opt/cmsingbox-license}"
admin_password="${CMSINGBOX_LICENSE_PASSWORD:-Aa666333}"
listen_port="${CMSINGBOX_LICENSE_PORT:-9093}"

if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 运行，或在命令中加入 sudo。" >&2
  exit 1
fi
if [ -z "$admin_password" ] || [ "${#admin_password}" -lt 8 ]; then
  echo "请通过 CMSINGBOX_LICENSE_PASSWORD 设置至少 8 位的授权端密码。" >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  echo "缺少 curl，请先安装 curl。" >&2
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

case "$(uname -m)" in
  x86_64|amd64) architecture="amd64" ;;
  aarch64|arm64) architecture="arm64" ;;
  armv7l|armv7) architecture="arm" ;;
  *) echo "不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$install_dir/license-data"
curl -fsSL "${repository_raw}/bin/cmsingbox-license-server-linux-${architecture}" -o "$install_dir/cmsingbox-license-server"
curl -fsSL "${repository_raw}/bin/cmsingbox-license-tool-linux-${architecture}" -o "$install_dir/cmsingbox-license-tool"
curl -fsSL "${repository_raw}/Dockerfile.license" -o "$install_dir/Dockerfile.license"
curl -fsSL "${repository_raw}/docker-compose.license.yml" -o "$install_dir/docker-compose.license.yml"
chmod 0755 "$install_dir/cmsingbox-license-server" "$install_dir/cmsingbox-license-tool"

password_hash="$(printf '%s' "$admin_password" | sha256sum | awk '{print $1}')"
umask 077
{
  printf 'CMSINGBOX_LICENSE_PASSWORD_HASH=%s\n' "$password_hash"
  printf 'CMSINGBOX_LICENSE_PORT=%s\n' "$listen_port"
} > "$install_dir/.env"

cd "$install_dir"
docker compose -f docker-compose.license.yml build
if [ ! -f license-data/private.key ]; then
  docker compose -f docker-compose.license.yml run --rm --no-deps \
    --entrypoint /usr/local/bin/cmsingbox-license-tool cmsingbox-license \
    keygen -private /license/private.key -public /license/public.key
fi
chmod 0600 license-data/private.key .env
docker compose -f docker-compose.license.yml up -d

echo
echo "授权中心已启动: http://服务器IP:${listen_port}"
echo "授权公钥: $(tr -d '\r\n' < license-data/public.key)"
echo "私钥目录: ${install_dir}/license-data"
echo "请立即离线备份 private.key；客户主程序部署时必须使用上面的公钥。"
