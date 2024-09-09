// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Passwordless",
    platforms: [
        .iOS(.v13),       // Set minimum deployment target for iOS
        .macOS(.v10_15),  // Set minimum deployment target for macOS
        .tvOS(.v13),      // Set minimum deployment target for tvOS
        .watchOS(.v6)     // Set minimum deployment target for watchOS
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Passwordless",
            targets: ["Passwordless"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Passwordless"),
        .testTarget(
            name: "passwordless-swiftTests",
            dependencies: ["Passwordless"]),
    ]
)
