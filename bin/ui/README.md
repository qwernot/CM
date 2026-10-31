# Bundled proxy console

MetaCubeXD, MIT. Pinned gh-pages commit `28a9589f6239bbafc24e87bbf5e5b4997fe42e59`.
This is the same static build already used on the user's 123 server: its original index.html SHA256 is `a36465d52fa4101101e7e78997f71d1400fb6b3e4c12a5d43eb8556abf3ffef3`.

- Source: https://github.com/MetaCubeX/metacubexd/tree/28a9589f6239bbafc24e87bbf5e5b4997fe42e59
- License: https://github.com/MetaCubeX/metacubexd/blob/main/LICENSE
- Repackaged ZIP SHA256: `5972615f00cd7572653b94fa3daf6e3e9051c7a9d76b9834eafb5ab81be53efd`
- Changes: remove the GitHub Pages CNAME, include license/provenance, and set config.js defaultBackendURL to window.location.origin. No server secrets or fixed IPs are included. Other upstream static assets are unchanged.

Reproduce with `python3 tools/bundle-metacubexd.py /path/to/pinned-gh-pages-checkout`.

The archive is embedded in CMSingBox and installed offline in its own versioned directory. Custom user UIs are never overwritten. CM mirrors the identical ZIP for explicit panel reinstallation; first start does not require a network download. Do not replace this pin with an untested latest build.
