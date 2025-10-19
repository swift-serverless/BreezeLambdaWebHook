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
import AsyncHTTPClient
@testable import BreezeLambdaWebHook
import Logging
import Foundation

@Suite("BreezeLambdaWebPostGetTests")
struct BreezeLambdaWebPostGetTests: ~Copyable {

    let decoder = JSONDecoder()
    let config = BreezeHTTPClientConfig(
        timeout: .seconds(1),
        logger: Logger(label: "test")
    )
    
    init() {
        setEnvironmentVar(name: "_HANDLER", value: "build/webhook", overwrite: true)
        setEnvironmentVar(name: "LOCAL_LAMBDA_SERVER_ENABLED", value: "true", overwrite: true)
    }
    
    deinit {
        unsetenv("LOCAL_LAMBDA_SERVER_ENABLED")
        unsetenv("_HANDLER")
    }
    
    @Test("PostWhenMissingBody_ThenError")
    func postWhenMissingBody_thenError() async throws {
        let createRequest = try Fixtures.fixture(name: Fixtures.getWebHook, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(MyPostWebHook.self, config: config, with: request)
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        
        #expect(apiResponse.statusCode == .badRequest)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }
    
    @Test("PostWhenBody_ThenValue")
    func postWhenBody_thenValue() async throws {
        let createRequest = try Fixtures.fixture(name: Fixtures.postWebHook, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(MyPostWebHook.self, config: config, with: request)
        let response: MyPostResponse = try apiResponse.decodeBody()
        let body: MyPostRequest = try request.bodyObject()
        
        #expect(apiResponse.statusCode == .ok)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.body == body.value)
        #expect(response.handler == "build/webhook")
    }
    
    @Test("GetWhenMissingQuery_ThenError")
    func getWhenMissingQuery_thenError() async throws {
        let createRequest = try Fixtures.fixture(name: Fixtures.postWebHook, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(MyGetWebHook.self, config: config, with: request)
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        
        #expect(apiResponse.statusCode == .badRequest)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }
    
    @Test("GetWhenQuery_ThenValue")
    func getWhenQuery_thenValue() async throws {
        let createRequest = try Fixtures.fixture(name: Fixtures.getWebHook, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(MyGetWebHook.self, config: config, with: request)
        let response: [String: String] = try apiResponse.decodeBody()
        
        #expect(apiResponse.statusCode == .ok)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.count == 2)
    }
}
