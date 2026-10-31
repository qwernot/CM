#!/bin/sh
# Read-only preflight. Never changes routes, sysctls, devices or firewall rules.
set -eu
mode="${1:-native}"
case "$mode" in native|macvlan|bridge) ;; *) echo '用法: check-network.sh native|macvlan|bridge' >&2; exit 2;; esac
issues=0
warn() { echo "[需检查] $*"; issues=$((issues + 1)); }
echo "CMSingBox 网关预检：${mode}（只读，不修改系统）"
[ "$(uname -s)" = Linux ] || { echo 'TUN 网关需 Linux 环境'; exit 1; }
if [ -c /dev/net/tun ]; then
  echo '[正常] /dev/net/tun 存在（创建 TUN 仍需 root 或 NET_ADMIN）'
else
  warn '缺少 /dev/net/tun。原生宿主机可检查 tun 模块；Docker 应映射设备并提供 NET_ADMIN。RouterOS 应使用其兼容模式，不要在 ROS 中运行 modprobe。'
fi
if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = 1 ]; then
  echo '[正常] 当前网络命名空间已开启 IPv4 转发'
else
  warn 'IPv4 转发未开启；作为网关前请显式设置 net.ipv4.ip_forward=1，并通过 /etc/sysctl.d 持久化。'
fi
if command -v ip >/dev/null 2>&1; then
  echo '当前默认出口：'
  ip -4 route show default
  echo '当前策略路由（有其他代理/VPN 时注意冲突）：'
  ip -4 rule show
else
  warn '缺少 iproute2，无法检查默认出口及策略路由'
fi
if command -v ss >/dev/null 2>&1; then
  echo 'DNS/管理/控制端口监听（检查是否被其他程序占用）：'
  ss -lntu | awk 'NR == 1 || $5 ~ /:(53|80|2080|9090|9092)$/'
fi
case "$mode" in
  native)
    echo '终端网关/DNS填本机局域网 IP；开启 TUN 和 auto_route，Linux 推荐 auto_redirect。'
    echo '检查宿主机 FORWARD/DOCKER-USER/UFW/firewalld 是否允许指定 LAN 的转发；本脚本不会放开所有来源。'
    ;;
  macvlan)
    echo '终端网关/DNS填容器独立局域网 IP，不是宿主机 IP。'
    echo '本脚本应在容器内再执行一次，以检查容器的 TUN 和转发状态。'
    echo '宿主机到 macvlan 容器的隔离需 shim；Wi-Fi/云平台可能禁止多个 MAC。'
    ;;
  bridge)
    warn 'bridge 仅映射端口不能作为 LAN 网关；需宿主机到容器的策略路由及定向 FORWARD 放行。推荐原生或 macvlan，避免盲目添加全局路由。'
    ;;
esac
echo '验证必须在另一台 LAN 设备完成：先查 DNS，再访问国内/国外 HTTPS，查看 TUN 日志是否收到该设备的源 IP。'
echo "预检完成：${issues} 项需检查。此脚本不替代实际转发测试。"
[ "$issues" -eq 0 ]
