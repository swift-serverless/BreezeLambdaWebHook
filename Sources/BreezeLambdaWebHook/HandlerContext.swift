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

///
/// `HandlerContext` provides a context for Lambda handlers, encapsulating an HTTP client and configuration.
///
/// This struct is responsible for managing the lifecycle of the HTTP client used for outbound requests,
/// including graceful and synchronous shutdown procedures. It also provides logging for lifecycle events.
///
/// - Parameters:
///    - httpClient: The HTTP client used for making outbound HTTP requests.
///    - config: The configuration for the HTTP client, including timeout and logger.
///
///  - Conforms to: `Service`
public struct HandlerContext: Service {
    /// The HTTP client used for outbound requests.
    public let httpClient: HTTPClient
    /// The configuration for the HTTP client.
    private let config: BreezeHTTPClientConfig
    
    /// Initializes a new `HandlerContext` with the provided configuration.
    /// - Parameter config: The configuration for the HTTP client.
    public init(config: BreezeHTTPClientConfig) {
        let timeout = HTTPClient.Configuration.Timeout(
            connect: config.timeout,
            read: config.timeout
        )
        let configuration = HTTPClient.Configuration(timeout: timeout)
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )
        self.config = config
    }

    /// Runs the `HandlerContext` and waits for a graceful shutdown.
    public func run() async throws {
        config.logger.info("BreezeHTTPClientProvider started")
        try await gracefulShutdown()
        config.logger.info("BreezeHTTPClientProvider is gracefully shutting down ...")
        try await onGracefulShutdown()
    }

    /// Handles graceful shutdown of the HTTP client.
    public func onGracefulShutdown() async throws {
        try await httpClient.shutdown()
        config.logger.info("BreezeHTTPClientProvider: HTTPClient shutdown is completed.")
    }

    /// Synchronously shuts down the HTTP client.
    public func syncShutdown() throws {
        try httpClient.syncShutdown()
        config.logger.info("BreezeHTTPClientProvider: HTTPClient syncShutdown is completed.")
    }
}
