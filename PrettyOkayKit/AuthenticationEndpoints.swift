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
import ReactiveCocoa
import Result
import Shirley

// MARK: - Authentication Endpoint
struct AuthenticationEndpoint
{
    let username: String
    let password: String
    let token: String
    let cookies: [NSHTTPCookie]
}

extension AuthenticationEndpoint: EndpointType
{
    var request: NSURLRequest?
    {
        return NSURL(string: "https://verygoods.co/login").map({ URL in
            // build a POST request
            let request = NSMutableURLRequest(URL: URL)
            request.HTTPMethod = "POST"
            request.setValue("https://verygoods.co/login", forHTTPHeaderField: "Referer")

            // add cookie header fields
            for (header, value) in NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)
            {
                request.setValue(value, forHTTPHeaderField: header)
            }

            // build a form data string from query items
            let components = NSURLComponents()
            components.queryItems = [
                NSURLQueryItem(name: "username", value: self.username),
                NSURLQueryItem(name: "password", value: self.password),
                NSURLQueryItem(name: "_csrf_token", value: token),
                NSURLQueryItem(name: "next", value: "")
            ]

            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = components.query?.dataUsingEncoding(NSUTF8StringEncoding)
            
            return request
        })
    }
}

extension AuthenticationEndpoint: ProcessingType
{
    func resultForInput(message: Message<NSHTTPURLResponse, NSData>) -> Result<Authentication, NSError>
    {
        guard let headers = message.response.allHeaderFields as? [String:String] else {
            return .Failure(AuthenticationError.InvalidHeaders.NSError)
        }

        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(
            headers,
            forURL: NSURL(string: "https://verygoods.co")!
        )

        guard let tokenCookie = cookies.filter({ $0.name == "remember_token" }).first else {
            return .Failure(AuthenticationError.FailedToFindTokenCookie.NSError)
        }

        guard let sessionCookie = cookies.filter({ $0.name == "session" }).first else {
            return .Failure(AuthenticationError.FailedToFindSessionCookie.NSError)
        }

        return .Success(Authentication(username: username, token: tokenCookie, session: sessionCookie))
    }
}

// MARK: - Authentication Errors

/// The errors that may occur during authentication.
public enum AuthenticationError: Int, ErrorType
{
    // MARK: - Errors

    /// The response headers were invalid.
    case InvalidHeaders

    /// The token cookie could not be found.
    case FailedToFindTokenCookie

    /// The session cookie could not be found.
    case FailedToFindSessionCookie
}

extension AuthenticationError: NSErrorConvertible
{
    // MARK: - Error Domain

    /// The error domain for `AuthenticationError` values.
    public static var domain: String { return "PrettyOkay.AuthenticationError" }
}

extension AuthenticationError: UserInfoConvertible
{
    // MARK: - User Info

    /// A description of the error.
    public var localizedDescription: String?
    {
        switch self
        {
        case .InvalidHeaders:
            return "Invalid headers."
        case .FailedToFindTokenCookie:
            return "Failed to find token cookie."
        case .FailedToFindSessionCookie:
            return "Failed to find session cookie."
        }
    }
}
