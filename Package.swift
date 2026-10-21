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
        .library(
            name: "BiometricSessionKeychain",
            targets: ["BiometricSessionKeychain"]
        ),
        .library(
            name: "BiometricSessionUIKit",
            targets: ["BiometricSessionUIKit"]
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
        .target(
            name: "BiometricSessionKeychain",
            dependencies: ["BiometricSessionCore"]
        ),
        .target(
            name: "BiometricSessionUIKit",
            dependencies: ["BiometricSessionCore"]
        ),
        .testTarget(
            name: "BiometricSessionCoreTests",
            dependencies: ["BiometricSessionCore", "BiometricSessionTestSupport"]
        ),
        .testTarget(
            name: "BiometricSessionTestSupportTests",
            dependencies: ["BiometricSessionCore", "BiometricSessionTestSupport"]
        ),
        .testTarget(
            name: "BiometricSessionLocalAuthTests",
            dependencies: ["BiometricSessionCore", "BiometricSessionLocalAuth"]
        ),
        .testTarget(
            name: "BiometricSessionKeychainTests",
            dependencies: ["BiometricSessionCore", "BiometricSessionKeychain"]
        ),
        .testTarget(
            name: "BiometricSessionUIKitTests",
            dependencies: [
                "BiometricSessionCore",
                "BiometricSessionTestSupport",
                "BiometricSessionUIKit",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
