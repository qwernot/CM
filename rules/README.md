# CMSingBox 运行规则镜像

此目录保存 CMSingBox 默认配置实际使用的 sing-box `.srs` 规则文件，避免新装设备在运行时依赖第三方规则仓库。

- `geosite/`：域名规则。
- `rule-set-geoip/`：IP 规则。
- `SHA256SUMS`：当前镜像文件的完整性校验。

这些文件是规则数据，不包含可执行代码。当前快照来源于 `lyc8503/sing-box-rules` 的公开构建产物；CMSingBox 默认只从本仓库地址读取镜像。更新规则时应先在测试机执行 `sing-box check`，再替换本目录文件。
