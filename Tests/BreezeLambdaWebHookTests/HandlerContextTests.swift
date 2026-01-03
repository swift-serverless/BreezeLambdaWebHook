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

import Testing
import AWSLambdaEvents
import AWSLambdaRuntime
@testable import AsyncHTTPClient
@testable import BreezeLambdaWebHook
@testable import ServiceLifecycle
import ServiceLifecycleTestKit
import Logging
import Foundation

@Suite("HandlerContextTests")
struct HandlerContextTests {
    
    @Test("HandlerContextInitialization")
    func handlerContextInitializesWithConfig() throws {
        let logger = Logger(label: "test")
        let config = BreezeHTTPClientConfig(timeout: .seconds(1), logger: logger)
        let context = HandlerContext(config: config)
        #expect(context.httpClient.configuration.timeout.connect == .seconds(1))
        try context.syncShutdown()
    }

    @Test("HandlerContextRun")
    func handlerContextRunPerformsGracefulShutdown() async throws {
        let logger = Logger(label: "test")
        let config = BreezeHTTPClientConfig(timeout: .seconds(10), logger: logger)
        let context = HandlerContext(config: config)
        await testGracefulShutdown { gracefulShutdownTestTrigger in
            let (gracefulStream, continuation) = AsyncStream<Void>.makeStream()
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    gracefulShutdownTestTrigger.triggerGracefulShutdown()
                }
                group.addTask {
                    try await withGracefulShutdownHandler {
                        try await context.run()
                    } onGracefulShutdown: {
                        logger.info("On Graceful Shutdown")
                        continuation.yield()
                    }
                }
                for await _ in gracefulStream {
                    continuation.finish()
                    logger.info("Graceful shutdown stream received")
                    #expect(context.httpClient.configuration.timeout.read == .seconds(10))
                    #expect(context.httpClient.configuration.timeout.connect == .seconds(10))
                    group.cancelAll()
                }
            }
        }
    }

    @Test("HandlerContextOnGracefulShutdown")
    func handlerContextOnGracefulShutdownShutsDownHTTPClient() async throws {
        let logger = Logger(label: "test")
        let config = BreezeHTTPClientConfig(timeout: .seconds(1), logger: logger)
        let context = HandlerContext(config: config)
        try await context.onGracefulShutdown()
        #expect(true) // If no error is thrown, shutdown completed successfully
    }

    @Test("HandlerContextSyncShutdown")
    func handlerContextSyncShutdownShutsDownHTTPClient() {
        
        let logger = Logger(label: "test")
        let config = BreezeHTTPClientConfig(timeout: .seconds(1), logger: logger)
        let context = HandlerContext(config: config)
        do {
            try context.syncShutdown()
        } catch {
            Issue.record("Expected syncShutdown to complete without errors, but got: \(error)")
        }
    }

    @Test("HandlerContextSyncShutdownThrowsAfterShutdown")
    func handlerContextSyncShutdownThrowsAfterShutdown() {
        let logger = Logger(label: "test")
        let config = BreezeHTTPClientConfig(timeout: .seconds(1), logger: logger)
        let context = HandlerContext(config: config)
        try? context.syncShutdown()
        #expect(throws: Error.self) {
            try context.syncShutdown()
        }
    }
}
