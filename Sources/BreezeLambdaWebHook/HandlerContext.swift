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

public struct HandlerContext: Service {
    public let httpClient: HTTPClient
    private let config: BreezeHTTPClientConfig
    
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

    public func run() async throws {
        config.logger.info("BreezeHTTPClientProvider started")
        try await gracefulShutdown()
        config.logger.info("BreezeHTTPClientProvider is gracefully shutting down ...")
        try await onGracefulShutdown()
    }

    public func onGracefulShutdown() async throws {
        try await httpClient.shutdown()
        config.logger.info("BreezeHTTPClientProvider: HTTPClient shutdown is completed.")
    }

    public func syncShutdown() throws {
        try httpClient.syncShutdown()
        config.logger.info("BreezeHTTPClientProvider: HTTPClient syncShutdown is completed.")
    }
}
