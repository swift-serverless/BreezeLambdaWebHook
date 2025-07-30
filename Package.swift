// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreezeLambdaWebHook",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "BreezeLambdaWebHook",
            targets: ["BreezeLambdaWebHook"]
        ),
        .executable(
            name: "BreezeDemoHTTPApplication",
            targets: ["BreezeDemoHTTPApplication"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "2.0.0-beta.1"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "0.5.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.22.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.3"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
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
        .executableTarget(
            name: "BreezeDemoHTTPApplication",
            dependencies: [
                "BreezeLambdaWebHook"
            ]
        ),
        .testTarget(
            name: "BreezeLambdaWebHookTests",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "ServiceLifecycleTestKit", package: "swift-service-lifecycle"),
                "BreezeLambdaWebHook"
            ],
            resources: [.copy("Fixtures")]
        ),
    ]
)
