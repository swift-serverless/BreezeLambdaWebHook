// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)
let platforms: [PackageDescription.SupportedPlatform]? = [.macOS(.v15), .iOS(.v13)]
#else
let platforms: [PackageDescription.SupportedPlatform]? = nil
#endif

let package = Package(
    name: "BreezeLambdaWebHook",
    platforms: platforms,
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
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", branch: "main"),
//        .package(path: "../swift-aws-lambda-runtime"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "0.5.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.11.2"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.3")
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
