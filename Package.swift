// swift-tools-version: 6.2
// Copyright 2026 John Salerno.
import PackageDescription

let package = Package(
    name: "ButterflyButton",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ButterflyButton",
            targets: ["ButterflyButton"]
        )
    ],
    targets: [
        .target(
            name: "ButterflyButton",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ButterflyButtonTests",
            dependencies: ["ButterflyButton"]
        )
    ]
)
