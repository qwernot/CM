# CMSingBox 中文部署文档

本仓库只保存 CMSingBox 的中文部署文档、一键安装脚本、公开运行二进制和容器构建文件，不包含授权私钥。

部署包已内置 sing-box 1.13.21 基础内核，安装完成即可使用；以后仍可在后台下载并替换内核。第三方内核的来源、许可证和校验信息见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 在线文档

[https://qwernot.github.io/CM/](https://qwernot.github.io/CM/)

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

## 目录

- `docs/user`：普通用户功能与排障文档
- `docs/deploy`：原生、Docker 与 RouterOS 部署教程
- `deploy`：普通主程序安装脚本与 Docker 配置
- `bin`：普通主程序多架构二进制

管理员授权端、授权文档和完整项目源代码不在本公开仓库中。
