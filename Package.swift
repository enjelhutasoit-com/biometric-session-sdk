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
            targets: ["BiometricSessionCore"]
        ),
        .library(
            name: "BiometricSessionTestSupport",
            targets: ["BiometricSessionTestSupport"]
        ),
        .library(
            name: "BiometricSessionLocalAuth",
            targets: ["BiometricSessionLocalAuth"]
        ),
    ],
    targets: [
        .target(
            name: "BiometricSessionCore"
        ),
        .target(
            name: "BiometricSessionTestSupport",
            dependencies: ["BiometricSessionCore"]
        ),
        .target(
            name: "BiometricSessionLocalAuth",
            dependencies: ["BiometricSessionCore"]
        ),
        .testTarget(
            name: "BiometricSessionCoreTests",
            dependencies: ["BiometricSessionCore"]
        ),
        .testTarget(
            name: "BiometricSessionTestSupportTests",
            dependencies: ["BiometricSessionCore", "BiometricSessionTestSupport"]
        ),
        .testTarget(
            name: "BiometricSessionLocalAuthTests",
            dependencies: ["BiometricSessionCore", "BiometricSessionLocalAuth"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
