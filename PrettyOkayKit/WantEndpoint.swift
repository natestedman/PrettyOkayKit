// Copyright (c) 2016, Nate Stedman <nate@natestedman.com>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
// PERFORMANCE OF THIS SOFTWARE.

import Endpoint
import Foundation
import Result

// MARK: - Wanting

/// An endpoint for wanting a product.
internal struct WantEndpoint: CSRFTokenEndpoint
{
    // MARK: - Initialization

    /**
     Initializes a want endpoint.

     - parameter identifier: The identifier of the product to want.
     */
    init(username: String, identifier: ModelIdentifier, CSRFToken: String)
    {
        self.username = username
        self.identifier = identifier
        self.CSRFToken = CSRFToken
    }

    // MARK: - Data

    /// The username of the user wanting the product.
    let username: String

    /// The identifier of the product to want.
    let identifier: ModelIdentifier

    /// The CSRF token for the request.
    let CSRFToken: String
}

extension WantEndpoint: Encoding
{
    var encoded: [String : Any]
    {
        return ["product_id": identifier]
    }
}

extension WantEndpoint: BaseURLEndpoint,
                        BodyProvider,
                        HeaderFieldsProvider,
                        HTTPMethodProvider,
                        RelativeURLStringProvider
{
    var httpMethod: HTTPMethod { return .post }
    var relativeURLString: String { return "users/\(username.pathEscaped)/goods" }
}

extension WantEndpoint: ProcessingType
{
    func resultForInput(_ input: Any) -> Result<String?, NSError>
    {
        return .success(
            (input as? [String:Any])
                .flatMap({ $0["_links"] as? [String:Any] })
                .flatMap({ $0["self"] as? [String:Any] })
                .flatMap({ $0["href"] as? String })
                .map({ $0.removeLeadingCharacter })
        )
    }
}

// MARK: - Unwanting

/// An endpoint for unwanting a product.
internal struct UnwantEndpoint: CSRFTokenEndpoint
{
    // MARK: - Initialization

    /// Initializes an unwant endpoint
    ///
    /// - parameter goodDeletePath: The URL path to use.
    /// - parameter CSRFToken:      The CSRF token to use.
    init(goodDeletePath: String, CSRFToken: String)
    {
        self.goodDeletePath = goodDeletePath
        self.CSRFToken = CSRFToken
    }

    // MARK: - Data

    /// The URL path to request.
    let goodDeletePath: String

    /// A CSRF token.
    let CSRFToken: String
}

extension UnwantEndpoint: BaseURLEndpoint,
                          HeaderFieldsProvider,
                          HTTPMethodProvider,
                          RelativeURLStringProvider
{
    var httpMethod: HTTPMethod { return .delete }
    var relativeURLString: String { return goodDeletePath }
    var headerFields: [String : String] { return ["Csrf-Token": CSRFToken] }
}

extension UnwantEndpoint: ProcessingType
{
    func resultForInput(_ input: Any) -> Result<String?, NSError>
    {
        return .success(nil)
    }
}

/// A protocol for endpoints that require a CSRF token.
protocol CSRFTokenEndpoint
{
    /// The CSRF token.
    var CSRFToken: String { get }
}

// MARK: - Encodable Endpoint Extension
extension Encoding where Self: BodyProvider, Self: HeaderFieldsProvider, Self: CSRFTokenEndpoint
{
    var body: HTTPBody?
    {
        return try? JSONSerialization.data(withJSONObject: encoded, options: [])
    }

    var headerFields: [String: String]
    {
        return [
            "Content-Type": "application/json;charset=UTF-8",
            "Csrf-Token": CSRFToken,
            "Origin": "https://verygoods.co",
            "X-Requested-With": "XMLHttpRequest",
            "Referer": "https://verygoods.co"
        ]
    }
}
