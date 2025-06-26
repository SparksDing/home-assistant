// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueToothWifiConfiguration",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BlueToothWifiConfiguration",
            targets: ["BlueToothWifiConfiguration"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/hmlongco/Factory", from: "2.3.0"),
        .package(url: "https://github.com/bradleymackey/swift-spyable", branch: "feature/modifiers"),
        .package(path: "../ApplicationConfiguration"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BlueToothWifiConfiguration",
            dependencies: [
                "Factory",
                "ApplicationConfiguration",
                .product(name: "Spyable", package: "swift-spyable"),
            ]
        ),
        .testTarget(
            name: "BlueToothWifiConfigurationTests",
            dependencies: [
                "Factory",
                "BlueToothWifiConfiguration",
                .product(name: "Spyable", package: "swift-spyable"),
            ]),
    ]
)
