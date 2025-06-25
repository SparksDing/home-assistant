// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApplicationConfiguration",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ApplicationConfiguration",
            targets: ["ApplicationConfiguration"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/hmlongco/Factory", from: "2.3.0"),
        .package(url: "https://github.com/realm/realm-swift", from: "10.45.0"),
        .package(url: "https://github.com/bradleymackey/swift-spyable", branch: "feature/modifiers"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ApplicationConfiguration",
            dependencies: [
                "Factory",
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "Spyable", package: "swift-spyable"),
            ]
        )
    ]
)
