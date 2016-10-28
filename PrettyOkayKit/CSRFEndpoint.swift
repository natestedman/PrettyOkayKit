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
import NSErrorRepresentable
import Result
import Shirley

// MARK: - Purpose
enum CSRFEndpointPurpose
{
    case Login
    case Authenticated(Authentication)
}

extension CSRFEndpointPurpose
{
    private var authentication: Authentication?
    {
        switch self
        {
        case .Login:
            return nil
        case .Authenticated(let authentication):
            return authentication
        }
    }

    private var URLString: String
    {
        switch self
        {
        case .Login:
            return "https://verygoods.co/login"
        case .Authenticated:
            return "https://verygoods.co/"
        }
    }

    private var request: NSURLRequest?
    {
        return NSURL(string: URLString).map({ URL in
            let request = NSMutableURLRequest(URL: URL)
            request.HTTPShouldHandleCookies = false
            request.cachePolicy = .ReloadIgnoringCacheData
            authentication?.applyToMutableURLRequest(request)
            return request
        })
    }
}

// MARK: - Endpoint
struct CSRFEndpoint: EndpointType
{
    let purpose: CSRFEndpointPurpose
    
    var request: NSURLRequest? { return purpose.request }
}

extension CSRFEndpoint: ProcessingType
{
    func resultForInput(message: Message<NSHTTPURLResponse, NSData>)
        -> Result<(token: String, cookies: [NSHTTPCookie]), NSError>
    {
        // parse HTML for the CSRF token
        let HTML = HTMLDocument(data: message.body, contentTypeHeader: nil)

        guard let head = HTML.rootElement?.childElementNodes.lazy.filter({ element in
            element.tagName.lowercaseString == "head"
        }).first
        else { return .Failure(CSRFError.FailedToFindHead.NSError) }

        guard let meta = head.childElementNodes.lazy.filter({ element in
            element.tagName.lowercaseString == "meta" && element.attributes["name"] == "csrf-token"
        }).first
        else { return .Failure(CSRFError.FailedToFindMeta.NSError) }

        guard let csrf = meta.attributes["content"] else {
            return .Failure(CSRFError.FailedToFindCSRF.NSError)
        }

        // extract response parameters
        guard let headers = message.response.allHeaderFields as? [String:String] else {
            return .Failure(CSRFError.FailedToFindHeaders.NSError)
        }

        guard let URL = message.response.URL else {
            return .Failure(CSRFError.FailedToFindURL.NSError)
        }

        // create current cookies
        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(headers, forURL: URL)
        return .Success((token: csrf, cookies: cookies))
    }
}

// MARK: - CSRF Errors

/// The errors that may occur while finding a CSRF token.
public enum CSRFError: Int, ErrorType
{
    // MARK: - Errors

    /// The `<head>` tag could not be found in the response.
    case FailedToFindHead

    /// The required `<meta>` tag could not be found in the response.
    case FailedToFindMeta

    /// The CSRF token could not be found in the response.
    case FailedToFindCSRF

    /// The headers could not be found in the response.
    case FailedToFindHeaders

    /// The URL could not be found in the response.
    case FailedToFindURL
}

extension CSRFError: NSErrorConvertible
{
    // MARK: - Error Domain

    /// The error domain for `AuthenticationCSRFError` values.
    public static var domain: String { return "PrettyOkay.AuthenticationCSRFError" }
}

extension CSRFError: UserInfoConvertible
{
    // MARK: - User Info

    /// A description of the error.
    public var localizedDescription: String?
    {
        switch self
        {
        case FailedToFindHead: return "Failed to find “head” tag."
        case FailedToFindMeta: return "Failed to find “meta” tag."
        case FailedToFindCSRF: return "Failed to find CSRF token."
        case FailedToFindHeaders: return "Failed to find headers."
        case FailedToFindURL: return "Failed to find URL."
        }
    }
}
