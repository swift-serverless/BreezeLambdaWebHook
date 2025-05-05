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
import BreezeHTTPClientService
import Logging

public struct HandlerContext: Sendable {
    public let handler: String?
    public let httpClient: HTTPClient
}

public actor BreezeLambdaWebHookService<Handler: BreezeLambdaWebHookHandler>: Service {
    
    private let serviceConfig: BreezeClientServiceConfig
    private var handlerContext: HandlerContext?
    
    public init(serviceConfig: BreezeClientServiceConfig) {
        self.serviceConfig = serviceConfig
    }

    public func run() async throws {
        let _handler = Lambda.env("_HANDLER")
        serviceConfig.logger.info("handler: \(_handler ?? "")")
        let httpClient = await serviceConfig.httpClientService.httpClient
        let handlerContext = HandlerContext(handler: _handler, httpClient: httpClient)
        self.handlerContext = handlerContext
        let runtime = LambdaRuntime(body: handler)
        try await runtime.run()
    }
    
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let handlerContext = handlerContext else {
            throw BreezeClientServiceError.invalidHttpClient
        }
        return try await Handler(handlerContext: handlerContext).handle(event, context: context)
    }
}

