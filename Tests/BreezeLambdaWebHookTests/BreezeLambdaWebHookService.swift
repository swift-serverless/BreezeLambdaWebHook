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
import AWSLambdaRuntime
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


@Suite("BreezeLambdaWebHookServiceTests")
struct BreezeLambdaWebHookServiceTests {
    
    let decoder = JSONDecoder()
    
    @Test("HandlerContext initializes with provided HTTP client")
    func handlerContextInitializesWithClient() throws {
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? httpClient.syncShutdown() }
        let context = HandlerContext(httpClient: httpClient)
        #expect(context.httpClient === httpClient)
    }
    
    @Test("Service creates HTTP client with correct timeout configuration")
    func serviceCreatesHTTPClientWithCorrectConfig() async throws {
        try await testGracefulShutdown { gracefulShutdownTestTrigger in
            let (gracefulStream, continuation) = AsyncStream<Void>.makeStream()
            try await withThrowingTaskGroup(of: Void.self) { group in
                let logger = Logger(label: "test")
                let config = BreezeHTTPClientConfig(timeout: .seconds(30), logger: logger)
                let sut = BreezeLambdaWebHookService<MockHandler>(config: config)
                group.addTask {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    gracefulShutdownTestTrigger.triggerGracefulShutdown()
                }
                group.addTask {
                    try await withGracefulShutdownHandler {
                        try await sut.run()
                        print("BreezeLambdaAPIService started successfully")
                    } onGracefulShutdown: {
                        logger.info("On Graceful Shutdown")
                        continuation.yield()
                        continuation.finish()
                    }
                }
                for await _ in gracefulStream {
                    logger.info("Graceful shutdown stream received")
                    let handlerContext = try #require(await sut.handlerContext)
                    #expect(handlerContext.httpClient.configuration.timeout.read == .seconds(30))
                    #expect(handlerContext.httpClient.configuration.timeout.connect == .seconds(30))
                    group.cancelAll()
                }
            }
        }
    }
    
    @Test("Handler throws when handlerContext is nil")
    func handlerThrowsWhenContextIsNil() async throws {
        let logger = Logger(label: "test")
        let config = BreezeHTTPClientConfig(timeout: .seconds(30), logger: logger)
        let service = BreezeLambdaWebHookService<MockHandler>(config: config)
        
        let createRequest = try Fixtures.fixture(name: Fixtures.getWebHook, type: "json")
        let event = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let context = LambdaContext(requestID: "req1", traceID: "trace1", invokedFunctionARN: "", deadline: .now(), logger: logger)
        
        await #expect(throws: BreezeClientServiceError.invalidHandler) {
            try await service.handler(event: event, context: context)
        }
    }
    
    @Test("Handler delegates to specific handler implementation")
    func handlerDelegatesToImplementation() async throws {
        try await testGracefulShutdown { gracefulShutdownTestTrigger in
            let (gracefulStream, continuation) = AsyncStream<Void>.makeStream()
            try await withThrowingTaskGroup(of: Void.self) { group in
                let logger = Logger(label: "test")
                let config = BreezeHTTPClientConfig(timeout: .seconds(30), logger: logger)
                let sut = BreezeLambdaWebHookService<MockHandler>(config: config)
                group.addTask {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    gracefulShutdownTestTrigger.triggerGracefulShutdown()
                }
                group.addTask {
                    try await withGracefulShutdownHandler {
                        try await sut.run()
                        print("BreezeLambdaAPIService started successfully")
                    } onGracefulShutdown: {
                        logger.info("On Graceful Shutdown")
                        continuation.yield()
                        continuation.finish()
                    }
                }
                for await _ in gracefulStream {
                    logger.info("Graceful shutdown stream received")
                    let createRequest = try Fixtures.fixture(name: Fixtures.getWebHook, type: "json")
                    let event = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
                    let context = LambdaContext(requestID: "req1", traceID: "trace1", invokedFunctionARN: "", deadline: .now(), logger: logger)
                    
                    let response = try await sut.handler(event: event, context: context)
                    let handlerContext = try #require(await sut.handlerContext)
                    #expect(response.statusCode == 200)
                    #expect(response.body == "Mock response")
                    #expect(handlerContext.httpClient.configuration.timeout.read == .seconds(30))
                    #expect(handlerContext.httpClient.configuration.timeout.connect == .seconds(30))
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
