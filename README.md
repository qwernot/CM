# CMSingBox 中文部署文档

本仓库只保存 CMSingBox 的中文部署文档、一键安装脚本、公开运行二进制和容器构建文件，不包含授权私钥。

部署包已内置 sing-box 1.13.21 稳定基础内核，安装完成即可使用；后台还提供 1.14.0 最新版供手动切换。第三方内核的来源、许可证和校验信息见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 在线文档

[https://666228.xyz/CM/](https://666228.xyz/CM/)

## 原生一键部署

适用于使用 systemd 的 Linux 服务器、小主机和虚拟机，不使用 Docker：

```bash
curl -fsSL https://raw.githubusercontent.com/qwernot/CM/main/deploy/install.sh | sudo sh
```

默认使用宿主机 IP，后台端口为 9092。原生部署会直接使用宿主机端口；如果 53、2080 或 9092 已被占用，请在后台修改对应端口，后台端口也可通过 `CMSINGBOX_PORT` 在安装时指定。

## Docker 独立 IP 部署

准备一个与 Docker 宿主机同网段、位于 DHCP 自动分配范围之外的空闲 IP：

```bash
curl -fsSL https://raw.githubusercontent.com/qwernot/CM/main/deploy/install-docker.sh | sudo env CMSINGBOX_IP=192.168.1.20 sh
```

把 `192.168.1.20` 换成实际地址。脚本会自动识别默认网卡和局域网网段，macvlan 网关默认为 `192.168.1.1`，并给容器分配独立 IP；其他网关可通过 `CMSINGBOX_GATEWAY` 覆盖。

公开镜像为 `darkver8/cmsingbox:latest`，支持 `linux/amd64`、`linux/arm64` 和 `linux/arm/v7`。手动部署可直接下载 `deploy/docker-compose.yml`，在同一个文件中修改容器 IP、网段、网关和宿主机 LAN 网卡后运行。

## 飞牛 fnOS FPK

飞牛 NAS 可在“应用中心 → 手动安装”上传 [`CMSingBox-fnOS-1.0.27-all.fpk`](docs/downloads/CMSingBox-fnOS-1.0.27-all.fpk)。安装程序会复用已有同网段 macvlan/ipvlan，或自动创建独立网络，避免与飞牛宿主机的 DNS 53 端口冲突。详细步骤见[飞牛 fnOS 教程](https://666228.xyz/CM/deploy/fnos.html)。

## 目录

- `docs/user`：普通用户功能与排障文档
- `docs/deploy`：原生、Docker、飞牛 fnOS、RouterOS、爱快、UniFi/UBNT、OPNsense 与通用路由器教程
- `deploy`：普通主程序安装脚本与 Docker 配置
- `bin`：普通主程序多架构二进制

文档已按“快速开始 → 部署方式 → 功能使用 → 分流与规则 → 回家配置 → 路由器配置 → 常见问题”组织。路由器部分涵盖 RouterOS、爱快、UniFi/UBNT、OPNsense 和支持静态路由的通用设备，统一说明 DNS 下发/劫持、FakeIP 与纯 IP 路由、按设备分流、NAT、防环回、验证和断网回滚。
