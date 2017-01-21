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
import HTMLReader
import Result
import Shirley

// MARK: - Purpose
enum CSRFEndpointPurpose
{
    case login
    case authenticated(Authentication)
}

extension CSRFEndpointPurpose
{
    fileprivate var authentication: Authentication?
    {
        switch self
        {
        case .login:
            return nil
        case .authenticated(let authentication):
            return authentication
        }
    }

    fileprivate var URLString: String
    {
        switch self
        {
        case .login:
            return "https://verygoods.co/login"
        case .authenticated:
            return "https://verygoods.co/"
        }
    }

    fileprivate var request: URLRequest?
    {
        return URL(string: URLString).map({ URL in
            var request = URLRequest(url: URL)
            request.httpShouldHandleCookies = false
            request.cachePolicy = .reloadIgnoringCacheData
            authentication?.apply(to: &request)
            return request
        })
    }
}

// MARK: - Endpoint
struct CSRFEndpoint: Endpoint
{
    let purpose: CSRFEndpointPurpose
    
    var request: URLRequest? { return purpose.request }
}

extension CSRFEndpoint: ResultProcessing
{
    func result(for message: Message<HTTPURLResponse, Data>)
        -> Result<(token: String, cookies: [HTTPCookie]), NSError>
    {
        // parse HTML for the CSRF token
        let HTML = HTMLDocument(data: message.body, contentTypeHeader: nil)

        guard let head = HTML.rootElement?.childElementNodes.lazy.filter({ element in
            element.tagName.lowercased() == "head"
        }).first
        else { return .failure(CSRFError.failedToFindHead as NSError) }

        guard let meta = head.childElementNodes.lazy.filter({ element in
            element.tagName.lowercased() == "meta" && element.attributes["name"] == "csrf-token"
        }).first
        else { return .failure(CSRFError.failedToFindMeta as NSError) }

        guard let csrf = meta.attributes["content"] else {
            return .failure(CSRFError.failedToFindCSRF as NSError)
        }

        // extract response parameters
        guard let headers = message.response.allHeaderFields as? [String:String] else {
            return .failure(CSRFError.failedToFindHeaders as NSError)
        }

        guard let URL = message.response.url else {
            return .failure(CSRFError.failedToFindURL as NSError)
        }

        // create current cookies
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: URL)
        return .success((token: csrf, cookies: cookies))
    }
}

// MARK: - CSRF Errors

/// The errors that may occur while finding a CSRF token.
public enum CSRFError: Int, Error
{
    // MARK: - Errors

    /// The `<head>` tag could not be found in the response.
    case failedToFindHead

    /// The required `<meta>` tag could not be found in the response.
    case failedToFindMeta

    /// The CSRF token could not be found in the response.
    case failedToFindCSRF

    /// The headers could not be found in the response.
    case failedToFindHeaders

    /// The URL could not be found in the response.
    case failedToFindURL
}

extension CSRFError: CustomNSError
{
    // MARK: - Error Domain

    /// The error domain for `AuthenticationCSRFError` values.
    public static var errorDomain: String { return "PrettyOkay.AuthenticationCSRFError" }
}

extension CSRFError: LocalizedError
{
    // MARK: - User Info

    /// A description of the error.
    public var errorDescription: String?
    {
        switch self
        {
        case .failedToFindHead: return "Failed to find “head” tag."
        case .failedToFindMeta: return "Failed to find “meta” tag."
        case .failedToFindCSRF: return "Failed to find CSRF token."
        case .failedToFindHeaders: return "Failed to find headers."
        case .failedToFindURL: return "Failed to find URL."
        }
    }
}
