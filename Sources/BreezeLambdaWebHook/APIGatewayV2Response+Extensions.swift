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

import struct AWSLambdaEvents.APIGatewayV2Response
import HTTPTypes
import class Foundation.JSONEncoder

/// Extensions for `APIGatewayV2Response` to simplify response creation
public extension APIGatewayV2Response {
    private static let encoder = JSONEncoder()

    /// Body of an error response
    struct BodyError: Codable {
        public let error: String
    }
    
    /// Initializer with body error and status code
    /// - Parameters:
    ///   - error: Error
    ///   - statusCode: HTTP Status Code
    init(with error: Error, statusCode: HTTPResponse.Status) {
        let bodyError = BodyError(error: String(describing: error))
        self.init(with: bodyError, statusCode: statusCode)
    }
    
    /// Initializer with decodable object, status code, and headers
    /// - Parameters:
    ///   - object: Encodable Object
    ///   - statusCode: HTTP Status Code
    ///   - headers: HTTP Headers
    ///  - Returns: APIGatewayV2Response
    ///
    ///  This initializer encodes the object to JSON and sets it as the body of the response.
    ///  If encoding fails, it defaults to an empty JSON object.
    ///  - Note: The `Content-Type` header is set to `application/json` by default.
    init<Output: Encodable>(
        with object: Output,
        statusCode: HTTPResponse.Status,
        headers: [String: String] = [ "Content-Type": "application/json" ]
    ) {
        var body = "{}"
        if let data = try? Self.encoder.encode(object) {
            body = String(data: data, encoding: .utf8) ?? body
        }
        self.init(
            statusCode: statusCode,
            headers: headers,
            body: body,
            isBase64Encoded: false
        )
    }
}
