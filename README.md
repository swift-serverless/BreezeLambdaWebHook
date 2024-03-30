# BreezeLambdaWebHook
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-serverless%2FBreezeLambdaWebHook%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swift-serverless/BreezeLambdaWebHook) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-serverless%2FBreezeLambdaWebHook%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swift-serverless/BreezeLambdaWebHook) ![Breeze CI](https://github.com/swift-serverless/BreezeLambdaWebHook/actions/workflows/swift-test.yml/badge.svg) [![codecov](https://codecov.io/gh/swift-serverless/BreezeLambdaWebHook/branch/main/graph/badge.svg?token=PJR7YGBSQ0)](https://codecov.io/gh/swift-serverless/BreezeLambdaWebHook)

[![security status](https://www.meterian.io/badge/gh/swift-serverless/BreezeLambdaWebHook/security?branch=main)](https://www.meterian.io/report/gh/swift-serverless/BreezeLambdaWebHook)
[![stability status](https://www.meterian.io/badge/gh/swift-serverless/BreezeLambdaWebHook/stability?branch=main)](https://www.meterian.io/report/gh/swift-serverless/BreezeLambdaWebHook)
[![licensing status](https://www.meterian.io/badge/gh/swift-serverless/BreezeLambdaWebHook/licensing?branch=main)](https://www.meterian.io/report/gh/swift-serverless/BreezeLambdaWebHook)

![Breeze](logo.png)

## Usage

Add the package dependency `BreezeLambdaWebHook` to a package:

```swift
// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreezeWebHook",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "WebHook", targets: ["WebHook"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-sprinter/BreezeLambdaWebHook.git", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "WebHook",
             dependencies: [
                .product(name: "BreezeLambdaWebHook", package: "Breeze"),
            ]
        )
    ]
)
```

Add the implementation to the Lambda:

```swift
import Foundation
import AWSLambdaEvents
import AWSLambdaRuntimeCore
import BreezeLambdaWebHook
import Foundation

enum WebHookError: Error {
    case invalidHandler
}

class WebHook: BreezeLambdaWebHookHandler {
    
    let handlerContext: HandlerContext
    
    required init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(context: AWSLambdaRuntimeCore.LambdaContext, event: AWSLambdaEvents.APIGatewayV2Request) async -> AWSLambdaEvents.APIGatewayV2Response {
        do {
            // Check the handler
            guard let handler = handlerContext.handler else {
                throw  WebHookError.invalidHandler
            }
            // Evaluate the event
            context.logger.info("event: \(event)")
            let incomingRequest: ... = try event.bodyObject()
            // Implement the business logic
            let body = ...
            // Return an APIGatewayV2Response
            return APIGatewayV2Response(with: body, statusCode: .ok)
        } catch {
            // Return an APIGatewayV2Response in case of error
            return APIGatewayV2Response(with: error, statusCode: .badRequest)
        }
    }
}
```

Add the Lambda runtime to the file `swift.main`
```
import Foundation
import AWSLambdaEvents
import AWSLambdaRuntimeCore
import BreezeLambdaWebHook

BreezeLambdaWebHook<WebHook>.main()
```

## Documentation

Refer to the main project https://github.com/swift-serverless/Breeze for more info and working examples.

## Contributing

Contributions are welcome! If you encounter any issues or have ideas for improvements, please open an issue or submit a pull request.



