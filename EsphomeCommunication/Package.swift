// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EsphomeCommunication",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EsphomeCommunication",
            targets: ["EsphomeCommunication"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/hmlongco/Factory", from: "2.3.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0"),
        .package(path: "../AppConfiguration"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "EsphomeCommunication",
            dependencies: [
                "Factory",
                "AppConfiguration",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
        .testTarget(
            name: "EsphomeCommunicationTests",
            dependencies: [
                "Factory",
                "AppConfiguration",
                "EsphomeCommunication",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]),
    ]
)
