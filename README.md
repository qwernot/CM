# CMSingBox 中文部署文档

本仓库只保存 CMSingBox 的中文部署文档、一键安装脚本、公开运行二进制和容器构建文件，不包含授权私钥。

## 在线文档

[https://qwernot.github.io/CM/](https://qwernot.github.io/CM/)

## Docker 一键部署

准备一个与 Docker 宿主机同网段、位于 DHCP 自动分配范围之外的空闲 IP：

```bash
curl -fsSL https://raw.githubusercontent.com/qwernot/CM/main/install.sh | sudo env CMSINGBOX_IP=192.168.1.20 sh
```

把 `192.168.1.20` 换成实际地址。脚本会自动识别默认网卡、网关和局域网网段，并使用 macvlan 给容器分配独立 IP。

## 授权中心

授权中心只由授权管理员部署，普通用户不要执行：

```bash
curl -fsSL https://raw.githubusercontent.com/qwernot/CM/main/install-license.sh | sudo env CMSINGBOX_LICENSE_PASSWORD='Aa666333' sh
```

完整说明见在线文档。
