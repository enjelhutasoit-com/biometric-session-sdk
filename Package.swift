// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BiometricSession",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "BiometricSessionCore",
            targets: ["BiometricSessionCore"])
    ],
    targets: [
        .target(
            name: "BiometricSessionCore"),
        .testTarget(
            name: "BiometricSessionCoreTests",
            dependencies: ["BiometricSessionCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
