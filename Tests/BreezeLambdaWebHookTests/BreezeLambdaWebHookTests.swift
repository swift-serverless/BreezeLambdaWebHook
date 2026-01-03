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

import Testing
@testable import AsyncHTTPClient
import AWSLambdaEvents
@testable import AWSLambdaRuntime
@testable import ServiceLifecycle
import ServiceLifecycleTestKit
@testable import BreezeLambdaWebHook
import Logging
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import NIOCore


@Suite(.serialized)
struct BreezeLambdaWebHookTests {
    
    let decoder = JSONDecoder()
    
    @Test("BreezeLambdaWebHook can be shutdown gracefully")
    func breezeLambdaWebHookCanBeShutdownGracefully() async throws {
        await testGracefulShutdown { gracefulShutdownTestTrigger in
            let (gracefulStream, continuation) = AsyncStream<Void>.makeStream()
            await withThrowingTaskGroup(of: Void.self) { group in
                let logger = Logger(label: "test")
                let config = BreezeHTTPClientConfig(timeout: .seconds(30), logger: logger)
                let sut = BreezeLambdaWebHook<MockHandler>.init(name: "Test", config: config)
                group.addTask {
                    try await withGracefulShutdownHandler {
                        try await sut.run()
                    } onGracefulShutdown: {
                        logger.info("On Graceful Shutdown")
                        continuation.yield()
                    }
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    gracefulShutdownTestTrigger.triggerGracefulShutdown()
                }
                for await _ in gracefulStream {
                    #expect(sut.name == "Test")
                    #expect(sut.config.timeout == .seconds(30))
                    continuation.finish()
                    logger.info("Graceful shutdown stream received")
                    group.cancelAll()
                }
            }
        }
    }
}

struct MockHandler: BreezeLambdaWebHookHandler {
    let handlerContext: HandlerContext
    
    init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(_ event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        return APIGatewayV2Response(
            statusCode: .ok,
            body: "Mock response"
        )
    }
}
