//    Copyright 2024 (c) Andrea Scuderi - https://github.com/swift-serverless
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

import BreezeLambdaWebHook
import AWSLambdaEvents
import AWSLambdaRuntime
import AsyncHTTPClient
import Logging
import NIOCore
import ServiceLifecycle

/// This is a simple example of a Breeze Lambda WebHook handler.
/// It uses the BreezeHTTPClientService to make an HTTP request to example.com
/// and returns the response body as a string.
struct DemoLambdaHandler: BreezeLambdaWebHookHandler, Sendable {
    var handlerContext: HandlerContext
    
    init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(_ event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        context.logger.info("Received event: \(event)")
        let request = HTTPClientRequest(url: "https://example.com")
        let response = try await handlerContext.httpClient.execute(request, timeout: .seconds(5))
        let bytes = try await response.body.collect(upTo: 1024 * 1024) // 1 MB Buffer
        let body = String(buffer: bytes)
        context.logger.info("Response body: \(body)")
        return APIGatewayV2Response(with: body, statusCode: .ok)
    }
}

/// This is the main entry point for the Breeze Lambda WebHook application.
/// It creates an instance of the BreezeHTTPApplication and runs it.
/// The application name is used for logging and metrics.
/// The timeout is used to set the maximum time allowed for the Lambda function to run.
/// The default timeout is 30 seconds, but it can be changed to any value.
///
/// Local Testing:
///
/// The application will listen for incoming HTTP requests on port 7000 when run locally.
///
/// Use CURL to invoke the Lambda function, passing a JSON file containg API Gateway V2 request:
///
/// `curl -X POST 127.0.0.1:7000/invoke -H "Content-Type: application/json" -d @Tests/BreezeLambdaWebHookTests/Fixtures/get_webhook_api_gtw.json`
@main
struct BreezeDemoHTTPApplication {
    
    static let applicationName = "BreezeDemoHTTPApplication"
    static let logger = Logger(label: "BreezeDemoHTTPApplication")
    
    static func main() async throws {
        let config = BreezeHTTPClientConfig(
            timeout: .seconds(30),
            logger: logger
        )
        let app = BreezeLambdaWebHook<DemoLambdaHandler>(
            name: applicationName,
            config: config,
        )
        try await app.run()
    }
}
