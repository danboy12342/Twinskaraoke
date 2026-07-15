// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LNPopupUI",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
    ],
    products: [
        .library(name: "LNPopupUI", type: .dynamic, targets: ["LNPopupUI"]),
        .library(name: "LNPopupUI-Static", type: .static, targets: ["LNPopupUI"]),
    ],
    dependencies: [
        .package(path: "../LNPopupController"),
        .package(
            url: "https://github.com/LeoNatan/LNSwiftUIUtils.git",
            exact: "1.1.5"
        ),
    ],
    targets: [
        .target(
            name: "LNPopupUI",
            dependencies: [
                .product(name: "LNSwiftUIUtils", package: "LNSwiftUIUtils"),
                .product(name: "LNPopupController-Static", package: "LNPopupController"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
