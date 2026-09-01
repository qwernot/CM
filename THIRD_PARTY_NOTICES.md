# 第三方组件说明

CMSingBox 部署包附带独立运行的 sing-box 基础内核，用于保证首次部署后无需再次访问 GitHub 即可启动代理功能。

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
