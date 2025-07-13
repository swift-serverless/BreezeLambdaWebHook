# ``BreezeLambdaWebHook``

@Metadata { 
   @PageImage(purpose: icon, source: "wind")
}

## Overview

BreezeLambdaWebHook is a Swift framework that simplifies the development of serverless webhook handlers for AWS Lambda.

It provides a clean, type-safe interface for processing HTTP requests from API Gateway and returning appropriate responses.

It allows you to define a handler that processes incoming webhook requests and returns appropriate responses using `AsyncHTTPClient` framework.

![BreezeLambdaWebHook Diagram](webhook)

## Key Features

- Serverless Architecture - Built specifically for AWS Lambda with API Gateway integration
- Webhook Handling: Processes incoming requests and returns responses
- Swift Concurrency: Fully compatible with Swift's async/await model
- Type Safety: Leverages Swift's type system with Codable support
- It supports both GET and POST requests
- Minimal Configuration - Focus on business logic rather than infrastructure plumbing

## How it works

The framework handles the underlying AWS Lambda event processing, allowing you to focus on implementing your webhook logic. When a request arrives through API Gateway:

1. The Lambda function receives the API Gateway event
2. BreezeLambdaWebHook deserializes the event into a Swift type
3. The handler processes the request, performing any necessary business logic
4. The handler returns a response, which is serialized back to the API Gateway format

## Getting Started
 
To create a webhook handler, implement the BreezeLambdaWebHookHandler protocol:

```swift
class MyWebhook: BreezeLambdaWebHookHandler {
    let handlerContext: HandlerContext
    
    required init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(context: LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        // Your webhook logic here
        return APIGatewayV2Response(with: "Success", statusCode: .ok)
    }
}
```

Then, implement the `main.swift` file to run the Lambda function:
```swift
import BreezeLambdaWebHook
import AWSLambdaEvents
import AWSLambdaRuntime
import AsyncHTTPClient
import Logging
import NIOCore

@main
struct BreezeDemoHTTPApplication {
    static func main() async throws {
        let app = BreezeLambdaWebHook<DemoLambdaHandler>(name: "BreezeDemoHTTPApplication")
        try await app.run()
    }
}
```

## Example WebHook Handlers

### GET WebHook example:

If the parameter `github-user` is present in the query string, the value is extracted and used to get the content from GitHub, the content is returned to the response payload.

```swift
class GetWebHook: BreezeLambdaWebHookHandler {
    
    let handlerContext: HandlerContext
    
    required init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(context: AWSLambdaRuntimeCore.LambdaContext, event: AWSLambdaEvents.APIGatewayV2Request) async -> AWSLambdaEvents.APIGatewayV2Response {
        do {
            context.logger.info("event: \(event)")
            guard let params = event.queryStringParameters else {
                throw BreezeLambdaWebHookError.invalidRequest
            }
            if let user = params["github-user"] {
                let url = "https://github.com/\(user)"
                let request = HTTPClientRequest(url: url)
                let response = try await httpClient.execute(request, timeout: .seconds(3))
                let bytes = try await response.body.collect(upTo: 1024 * 1024) // 1 MB Buffer
                let body = String(buffer: bytes)
                return APIGatewayV2Response(with: body, statusCode: .ok)
            } else {
                return APIGatewayV2Response(with: params, statusCode: .ok)
            }
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .badRequest)
        }
    }
}
```

### PostWebHook example:

If the parameter `github-user` is present in the JSON payload, the value is extracted and used to get the content from GitHub, the content is returned to the response payload.

```swift
struct PostWebHookRequest: Codable {
    let githubUser: String
    
    enum CodingKeys: String, CodingKey {
        case githubUser = "github-user"
    }
}

class PostWebHook: BreezeLambdaWebHookHandler {
    
    let handlerContext: HandlerContext
    
    required init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(context: AWSLambdaRuntimeCore.LambdaContext, event: AWSLambdaEvents.APIGatewayV2Request) async -> AWSLambdaEvents.APIGatewayV2Response {
        do {
            context.logger.info("event: \(event)")
            let incomingRequest: PostWebHookRequest = try event.bodyObject()
            let url = "https://github.com/\(incomingRequest.githubUser)"
            let request = HTTPClientRequest(url: url)
            let response = try await httpClient.execute(request, timeout: .seconds(3))
            let bytes = try await response.body.collect(upTo: 1024 * 1024) // 1 MB Buffer
            let body = String(buffer: bytes)
            return APIGatewayV2Response(with: body, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .badRequest)
        }
    }
}
```

## Deployment

Deploy your Lambda function using AWS CDK, SAM, Serverless or Terraform. The Lambda requires:

- API Gateway integration for HTTP requests

For step-by-step deployment instructions and templates, see the [Breeze project repository](https://github.com/swift-serverless/Breeze) for more info on how to deploy it on AWS.

