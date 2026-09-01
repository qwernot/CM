# 第三方组件说明

CMSingBox 部署包附带独立运行的 sing-box 基础内核，用于保证首次部署后无需再次访问 GitHub 即可启动代理功能；内核管理页还提供本仓库镜像的最新版本。

- 组件：sing-box
- 版本：1.13.21
- 上游项目：https://github.com/SagerNet/sing-box
- 对应源码：https://github.com/SagerNet/sing-box/tree/v1.13.21
- 发布页面：https://github.com/SagerNet/sing-box/releases/tag/v1.13.21
- 许可证：GNU General Public License v3.0 or later

附带文件及其上游压缩包 SHA-256：

```text
linux/amd64  24f9ef8e7234e13e71e74c3598a4164c5fe07b7b67ccc6e96cf68b54789f72cd
linux/arm64  3e30b876c9a93c19e503e2a2d6249cf05e6a26766553d4b61e1daf48223f304f
linux/armv7  a3edb2a40eeba461fa9c6e9e0fc97217e355154132a588abf89fc4f3f4d0240f
```

sing-box 是与 CMSingBox 管理程序分离的独立可执行文件。用户可以在后台自行更新或替换它。

## 可选最新版

- 组件：sing-box
- 版本：1.14.0
- 上游项目：https://github.com/SagerNet/sing-box
- 对应源码：https://github.com/SagerNet/sing-box/tree/v1.14.0
- 发布页面：https://github.com/SagerNet/sing-box/releases/tag/v1.14.0
- 许可证：GNU General Public License v3.0 or later

镜像文件对应的上游压缩包 SHA-256：

```text
linux/amd64  2375de6999f4f56ab46b4fc5ddf26a6aba1d3e61a0f4e7ddec2f4690457d5f63
linux/arm64  04d9b40bc98dc55b6f509ce3292145c65478f65866bea64826ebb2f382385088
linux/armv7  1a8a205e9429c6317f30c5ec112d13345966a91348ae942c9c1645d4b6140063
```

1.14.0 是可选最新版。为兼顾已有配置，首次部署仍默认使用 1.13.21，用户可在后台的内核管理中切换。
