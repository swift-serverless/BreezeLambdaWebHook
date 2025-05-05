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

import ServiceLifecycle
import AsyncHTTPClient
import NIOCore
import Logging

public protocol BreezeHTTPClientServing: Actor, Service {
    var httpClient: HTTPClient { get }
}

public actor BreezeHTTPClientService: BreezeHTTPClientServing {
    
    public let httpClient: HTTPClient
    let logger: Logger
    
    public init(timeout: TimeAmount, logger: Logger) {
        self.logger = logger
        let timeout = HTTPClient.Configuration.Timeout(
            connect: timeout,
            read: timeout
        )
        let configuration = HTTPClient.Configuration(timeout: timeout)
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )
        logger.info("HTTPClientService config:")
        logger.info("timeout \(timeout)")
    }

    public func run() async throws {
        logger.info("HTTPClientService started...")
        try await gracefulShutdown()
        
        logger.info("Stopping HTTPClientService...")
        try await httpClient.shutdown()
        logger.info("HTTPClientService shutdown completed.")
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
}
