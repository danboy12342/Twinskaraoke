// swift-tools-version: 6.2

import PackageDescription

let privateHeaderPaths = [
    "LNPopupController/Private",
    "LNPopupController/Private/TransitionAnimators",
    "LNPopupController/Private/Appearance",
    "LNPopupController/Private/Utils",
    "LNPopupController/Private/Titles",
    "LNPopupController/Private/Swift",
    "LNPopupController/Private/Minimization",
    "LNPopupController/Private/GestureRecognizers",
]

let package = Package(
    name: "LNPopupController",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "LNPopupController",
            type: .dynamic,
            targets: [
                "LNPopupController",
                "LNPopupController-ObjC",
                "LNPopupController-SwiftPrivate",
            ]
        ),
        .library(
            name: "LNPopupController-Static",
            type: .static,
            targets: [
                "LNPopupController",
                "LNPopupController-ObjC",
                "LNPopupController-SwiftPrivate",
            ]
        ),
    ],
    targets: [
        .target(
            name: "LNPopupController-ObjC",
            path: "LNPopupController",
            exclude: [
                "Info.plist",
                "LNPopupController.xcodeproj",
                "LNPopupController/Private/Swift",
            ],
            publicHeadersPath: "include",
            cSettings: privateHeaderPaths.map { .headerSearchPath($0) }
        ),
        .target(
            name: "LNPopupController-SwiftPrivate",
            dependencies: ["LNPopupController-ObjC"],
            path: "LNPopupController/LNPopupController/Private/Swift"
        ),
        .target(
            name: "LNPopupController",
            dependencies: ["LNPopupController-ObjC"],
            path: "LNPopupController+Swift"
        ),
    ],
    cxxLanguageStandard: .gnucxx20
)
