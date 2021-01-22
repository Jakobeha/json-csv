// swift-tools-version:5.2

import PackageDescription

let package = Package(
        name: "json-csv",
        products: [
            .executable(name: "json-csv", targets: ["json-csv"])
        ],
        dependencies: [
            .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        ],
        targets: [
            .target(name: "json-csv", dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        ]
)