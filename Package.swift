// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Graphs",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "Graphs",
            targets: ["Graphs"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Graphs",
            dependencies: [],
            path: "Graphs/Sources"),
        .testTarget(
            name: "GraphsTests",
            dependencies: ["Graphs"],
            path: "GraphsTests/Sources")
    ]
)
