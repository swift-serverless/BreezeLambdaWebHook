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

import BreezeLambdaWebHookService
import BreezeHTTPClientService
import AWSLambdaEvents
import AWSLambdaRuntime
import Logging

struct DemoLambdaHandler: BreezeLambdaWebHookHandler, Sendable {
    var handlerContext: HandlerContext
    
    init(handlerContext: HandlerContext) {
        self.handlerContext = handlerContext
    }
    
    func handle(_ event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        context.logger.info("Received event: \(event)")
        return APIGatewayV2Response(with: "Hello World", statusCode: .ok)
    }
}

@main
struct BreezeDemoApplication {
    static func main() async throws {
        do {
            let logger = Logger(label: "BreezeDemoApplication")
            let httpClientService = BreezeHTTPClientService(
                timeout: .seconds(60),
                logger: logger
            )
            let lambdaService = BreezeLambdaWebHookService<DemoLambdaHandler>.init(
                serviceConfig: BreezeClientServiceConfig(
                    httpClientService: httpClientService,
                    logger: logger
                )
            )
            try await lambdaService.run()
        } catch {
            print(error.localizedDescription)
        }
    }
}
