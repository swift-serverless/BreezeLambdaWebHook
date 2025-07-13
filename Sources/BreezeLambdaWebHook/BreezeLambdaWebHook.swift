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

import AWSLambdaEvents
import AWSLambdaRuntime
import ServiceLifecycle
import Logging
import NIOCore

public struct BreezeLambdaWebHook<LambdaHandler: BreezeLambdaWebHookHandler>: Service {
    
    public let name: String
    public let config: BreezeHTTPClientConfig
    
    public init(name: String, config: BreezeHTTPClientConfig) {
        self.name = name
        self.config = config
    }
    
    public func run() async throws {
        do {
            let lambdaService = BreezeLambdaWebHookService<LambdaHandler>(
                config: config
            )
            let serviceGroup = ServiceGroup(
                services: [lambdaService],
                gracefulShutdownSignals: [.sigterm, .sigint],
                logger: config.logger
            )
            config.logger.error("Starting \(name) ...")
            try await serviceGroup.run()
        } catch {
            config.logger.error("Error running \(name): \(error.localizedDescription)")
        }
    }
}
