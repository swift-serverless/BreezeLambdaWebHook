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

import Foundation
import AsyncHTTPClient
import AWSLambdaEvents
import Logging
import NIO
@testable import BreezeLambdaWebHook
@testable import AWSLambdaRuntime


extension Lambda {
    public static func test(
        _ handlerType: any BreezeLambdaWebHookHandler.Type,
        config: BreezeHTTPClientConfig,
        with event: APIGatewayV2Request) async throws -> APIGatewayV2Response {
            let logger = Logger(label: "evaluateHandler")
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()
            let timeout = HTTPClient.Configuration.Timeout(
                connect: config.timeout,
                read: config.timeout
            )
            let configuration = HTTPClient.Configuration(timeout: timeout)
            let httpClient = HTTPClient(
                eventLoopGroupProvider: .singleton,
                configuration: configuration
            )
            let sut = handlerType.init(
                handlerContext: HandlerContext(httpClient: httpClient)
            )
            let closureHandler = ClosureHandler { event, context in
                //Inject Mock Response
                try await sut.handle(event, context: context)
            }
            
            var handler = LambdaCodableAdapter(
                encoder: encoder,
                decoder: decoder,
                handler: LambdaHandlerAdapter(handler: closureHandler)
            )
            let data = try encoder.encode(event)
            let event = ByteBuffer(data: data)
            let writer = MockLambdaResponseStreamWriter()
            let context = LambdaContext.__forTestsOnly(
                requestID: UUID().uuidString,
                traceID: UUID().uuidString,
                invokedFunctionARN: "arn:",
                timeout: .milliseconds(6000),
                logger: logger
            )
            try await handler.handle(event, responseWriter: writer, context: context)
            let result = await writer.output ?? ByteBuffer()
            try await httpClient.shutdown()
            return try decoder.decode(APIGatewayV2Response.self, from: result)
        }
}

final actor MockLambdaResponseStreamWriter: LambdaResponseStreamWriter {
    private var buffer: ByteBuffer?
    
    var output: ByteBuffer? {
        self.buffer
    }
    
    func writeAndFinish(_ buffer: ByteBuffer) async throws {
        self.buffer = buffer
    }
    
    func write(_ buffer: ByteBuffer) async throws {
        fatalError("Unexpected call")
    }
    
    func finish() async throws {
        fatalError("Unexpected call")
    }
}

