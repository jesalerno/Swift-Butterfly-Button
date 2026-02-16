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
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.59.1")
    ],
    targets: [
        .target(
            name: "ButterflyButton",
            resources: [.process("Resources")],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .executableTarget(
            name: "ButterflyButtonMacDemo",
            dependencies: ["ButterflyButton"],
            path: "Examples/ButterflyButtonMacDemo",
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .executableTarget(
            name: "ButterflyButtoniOSDemo",
            dependencies: ["ButterflyButton"],
            path: "Examples/ButterflyButtoniOSDemo",
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "ButterflyButtonTests",
            dependencies: ["ButterflyButton"],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        )
    ]
)
