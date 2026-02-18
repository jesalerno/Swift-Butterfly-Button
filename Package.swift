// swift-tools-version: 5.10
// Copyright 2026 John Salerno.
import PackageDescription

let package = Package(
    name: "ButterflyButton",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ButterflyButton",
            targets: ["ButterflyButton"]
        ),
        .executable(
            name: "ButterflyButtonMacDemo",
            targets: ["ButterflyButtonMacDemo"]
        ),
        .executable(
            name: "ButterflyButtoniOSDemo",
            targets: ["ButterflyButtoniOSDemo"]
        )
    ],
    targets: [
        .target(
            name: "ButterflyButton",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "ButterflyButtonMacDemo",
            dependencies: ["ButterflyButton"],
            path: "Examples/ButterflyButtonMacDemo"
        ),
        .executableTarget(
            name: "ButterflyButtoniOSDemo",
            dependencies: ["ButterflyButton"],
            path: "Examples/ButterflyButtoniOSDemo"
        ),
        .testTarget(
            name: "ButterflyButtonTests",
            dependencies: ["ButterflyButton"]
        )
    ]
)
