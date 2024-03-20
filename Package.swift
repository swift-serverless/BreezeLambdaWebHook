// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreezeLambdaWebHook",
    platforms: [
        .macOS(.v13),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "BreezeLambdaWebHook",
            targets: ["BreezeLambdaWebHook"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha.1"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "0.1.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.11.2"),
    ],
    targets: [
        .target(
            name: "BreezeLambdaWebHook",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .testTarget(
            name: "BreezeLambdaWebHookTests",
            dependencies: [
                .product(name: "AWSLambdaTesting", package: "swift-aws-lambda-runtime"),
                "BreezeLambdaWebHook"
            ],
            resources: [.copy("Fixtures")]
        ),
    ]
)
