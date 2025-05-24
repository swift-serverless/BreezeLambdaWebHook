//    Copyright 2023 (c) Andrea Scuderi - https://github.com/swift-serverless
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

import AsyncHTTPClient
import AWSLambdaEvents
import AWSLambdaRuntime
import Foundation
import ServiceLifecycle
import Logging

public struct HandlerContext: Sendable {
    public let httpClient: HTTPClient
    
    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
}

public actor BreezeLambdaWebHookService<Handler: BreezeLambdaWebHookHandler>: Service {
    
    let config: BreezeHTTPClientConfig
    var handlerContext: HandlerContext?
    
    public init(config: BreezeHTTPClientConfig) {
        self.config = config
    }

    public func run() async throws {
        let timeout = HTTPClient.Configuration.Timeout(
            connect: config.timeout,
            read: config.timeout
        )
        let configuration = HTTPClient.Configuration(timeout: timeout)
        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )
        let handlerContext = HandlerContext(httpClient: httpClient)
        self.handlerContext = handlerContext
        let runtime = LambdaRuntime(body: handler)
        try await withGracefulShutdownHandler {
            try await runtime.run()
        } onGracefulShutdown: {
            do {
                self.config.logger.info("Shutting down HTTP client...")
                try httpClient.syncShutdown()
                self.config.logger.info("HTTP client has been shut down.")
            } catch {
                self.config.logger.error("Error shutting down HTTP client: \(error)")
            }
        }
    }
    
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let handlerContext = handlerContext else {
            throw BreezeClientServiceError.invalidHttpClient
        }
        return try await Handler(handlerContext: handlerContext).handle(event, context: context)
    }
}

