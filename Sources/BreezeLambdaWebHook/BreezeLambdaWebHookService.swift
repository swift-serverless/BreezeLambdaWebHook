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
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import ServiceLifecycle
import Logging

public struct HandlerContext: Sendable {
    public let httpClient: HTTPClient
    
    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
}

/// A service that runs a Breeze Lambda WebHook handler
///
/// This service is responsible for providing the necessary context and configuration to the handler,
/// including the HTTP client and any other required resources.
///
/// - Note: This service is designed to be used with the Breeze Lambda WebHook framework, which allows for handling webhooks in a serverless environment.
public actor BreezeLambdaWebHookService<Handler: BreezeLambdaWebHookHandler>: Service {
    
    let config: BreezeHTTPClientConfig
    var handlerContext: HandlerContext?
    let httpClient: HTTPClient
    
    /// Initialilizer with a configuration for the Breeze HTTP Client.
    public init(config: BreezeHTTPClientConfig) {
        self.config = config
        let timeout = HTTPClient.Configuration.Timeout(
            connect: config.timeout,
            read: config.timeout
        )
        let configuration = HTTPClient.Configuration(timeout: timeout)
        httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )
    }

    /// Runs the Breeze Lambda WebHook service.
    public func run() async throws {
        let handlerContext = HandlerContext(httpClient: httpClient)
        self.handlerContext = handlerContext
        let runtime = LambdaRuntime(body: handler)
        try await runTaskWithCancellationOnGracefulShutdown {
            try await runtime.run()
        } onGracefulShutdown: {
            self.config.logger.info("Shutting down HTTP client...")
            _ = self.httpClient.shutdown()
            self.config.logger.info("HTTP client has been shut down.")
        }
    }
    
    /// Handler function that processes incoming events.
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let handlerContext = handlerContext else {
            throw BreezeClientServiceError.invalidHandler
        }
        return try await Handler(handlerContext: handlerContext).handle(event, context: context)
    }
    
    /// Runs a task with cancellation on graceful shutdown.
    ///
    /// - Note: It's required to allow a full process shutdown without leaving tasks hanging.
    private func runTaskWithCancellationOnGracefulShutdown(
        operation: @escaping @Sendable () async throws -> Void,
        onGracefulShutdown: () async throws -> Void
    ) async throws {
        let (cancelOrGracefulShutdown, cancelOrGracefulShutdownContinuation) = AsyncStream<Void>.makeStream()
        let task = Task {
            try await withTaskCancellationOrGracefulShutdownHandler {
                try await operation()
            } onCancelOrGracefulShutdown: {
                cancelOrGracefulShutdownContinuation.yield()
                cancelOrGracefulShutdownContinuation.finish()
            }
        }
        for await _ in cancelOrGracefulShutdown {
            try await onGracefulShutdown()
            task.cancel()
        }
    }
    
    deinit {
        _ = httpClient.shutdown()
    }
}

