// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "db",
    products: [
        .library(
            name: "db",
            targets: ["db"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "db",
            dependencies: []),
        .testTarget(
            name: "dbTests",
            dependencies: ["db"]),
    ]
)
