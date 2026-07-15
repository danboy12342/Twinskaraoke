# Vendored Swift Packages

These packages are vendored at their latest upstream releases because
LNPopupController 4.4.11 generates invalid private-header search paths when it
is consumed through Swift Package Manager in this project.

| Package | Version | Upstream |
| --- | --- | --- |
| LNPopupUI | 3.0.4 | https://github.com/LeoNatan/LNPopupUI |
| LNPopupController | 4.4.11 | https://github.com/LeoNatan/LNPopupController |

The source and license files are unchanged. The local package manifests keep
the upstream products and targets, link LNPopupUI to the local controller, pin
LNSwiftUIUtils 1.1.5, and replace LNPopupController's generated private-header
paths with explicit paths that SwiftPM can resolve.
