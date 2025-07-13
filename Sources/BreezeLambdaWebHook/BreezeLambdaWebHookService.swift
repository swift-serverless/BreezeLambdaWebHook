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
    let httpClient: HTTPClient
    private var isStarted = false
    
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

    public func run() async throws {
        isStarted = true
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
    
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let handlerContext = handlerContext else {
            throw BreezeClientServiceError.invalidHttpClient
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

