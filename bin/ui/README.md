# Bundled proxy console

Zashboard **v3.22.0** (MIT), a version which still supports sing-box Clash API.
Do not replace with an unpinned latest release: upstream removed sing-box support starting with 3.23.0.

- Project: https://github.com/Zephyruso/zashboard
- Release: https://github.com/Zephyruso/zashboard/releases/tag/v3.22.0
- Source tag: v3.22.0, commit 07e5e5a (see upstream release).
- Original asset: https://github.com/Zephyruso/zashboard/releases/download/v3.22.0/dist-no-fonts.zip
- Original SHA256: 568085968af1d7266311effce22e9dbe4874da7e7b8b3dd609aac848d7d87b0b
- Redistribution SHA256: 3cd6efaba3f58df2e955f68c026ea75b328ecadd8b7e39221a8e6996a644e13f
- Our redistribution adds upstream LICENSE at `dist/LICENSE`; application assets are unchanged. The original third-party notices are retained. System fonts are used, not a required font CDN.

The archive is embedded in CMSingBox, installed offline into a versioned data subdirectory, and kept separate from user-downloaded console UIs. The public CM repository mirrors the identical redistribution archive for explicitly requested UI reinstallation. That mirror is not required for first start.
