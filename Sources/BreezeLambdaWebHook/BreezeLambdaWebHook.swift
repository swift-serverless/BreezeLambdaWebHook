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

/// The Service that handles Breeze Lambda WebHook functionality.
public struct BreezeLambdaWebHook<LambdaHandler: BreezeLambdaWebHookHandler>: Service {
    
    /// The name of the service, used for logging and identification.
    public let name: String
    /// Configuration for the Breeze HTTP Client.
    public let config: BreezeHTTPClientConfig
    
    /// Initializes a new instance of with the given name and configuration.
    /// - Parameters:
    ///  - name: The name of the service.
    ///  - config: Configuration for the Breeze HTTP Client.
    ///
    ///  This initializer sets up the Breeze Lambda WebHook service with a specified name and configuration.
    ///
    /// - Note: If no configuration is provided, a default configuration with a 30-second timeout and a logger will be used.
    public init(
        name: String,
        config: BreezeHTTPClientConfig? = nil
    ) {
        self.name = name
        let defaultConfig = BreezeHTTPClientConfig(
            timeout: .seconds(30),
            logger: Logger(label: "\(name)")
        )
        self.config = config ?? defaultConfig
    }
    
    /// Runs the Breeze Lambda WebHook service.
    /// - Throws: An error if the service fails to start or run.
    ///
    /// This method initializes the Breeze Lambda WebHook service and starts it,
    /// handling any errors that may occur during the process.
    /// It gracefully shuts down the service on termination signals.
    public func run() async throws {
        let handlerContext = HandlerContext(config: config)
        let lambdaHandler = LambdaHandler(handlerContext: handlerContext)
        let runtime = LambdaRuntime(body: lambdaHandler.handle)

        let serviceGroup = ServiceGroup(
            services: [handlerContext, runtime],
            gracefulShutdownSignals: [.sigterm, .sigint],
            logger: config.logger
        )
        do {
            config.logger.error("Starting \(name) ...")
            try await serviceGroup.run()
        } catch {
            try? handlerContext.syncShutdown()
            config.logger.error("Error running \(name): \(error.localizedDescription)")
        }
    }
}
