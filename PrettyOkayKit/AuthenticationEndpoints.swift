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
import ReactiveSwift
import Result
import Shirley

// MARK: - Authentication Endpoint
struct AuthenticationEndpoint
{
    let username: String
    let password: String
    let token: String
    let cookies: [HTTPCookie]
}

extension AuthenticationEndpoint: Endpoint
{
    var request: URLRequest?
    {
        return URL(string: "https://verygoods.co/login").map({ URL in
            // build a POST request
            let request = NSMutableURLRequest(url: URL)
            request.httpMethod = "POST"
            request.setValue("https://verygoods.co/login", forHTTPHeaderField: "Referer")

            // add cookie header fields
            for (header, value) in HTTPCookie.requestHeaderFields(with: cookies)
            {
                request.setValue(value, forHTTPHeaderField: header)
            }

            // build a form data string from query items
            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "username", value: self.username),
                URLQueryItem(name: "password", value: self.password),
                URLQueryItem(name: "_csrf_token", value: token),
                URLQueryItem(name: "next", value: "")
            ]

            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = components.query?.data(using: String.Encoding.utf8)
            
            return request as URLRequest
        })
    }
}

extension AuthenticationEndpoint: ResultProcessing
{
    func result(for message: Message<HTTPURLResponse, Data>) -> Result<Authentication, NSError>
    {
        guard let headers = message.response.allHeaderFields as? [String:String] else {
            return .failure(AuthenticationError.invalidHeaders as NSError)
        }

        let cookies = HTTPCookie.cookies(
            withResponseHeaderFields: headers,
            for: URL(string: "https://verygoods.co")!
        )

        guard let tokenCookie = cookies.filter({ $0.name == "remember_token" }).first else {
            return .failure(AuthenticationError.failedToFindTokenCookie as NSError)
        }

        guard let sessionCookie = cookies.filter({ $0.name == "session" }).first else {
            return .failure(AuthenticationError.failedToFindSessionCookie as NSError)
        }

        return .success(Authentication(username: username, token: tokenCookie, session: sessionCookie))
    }
}

// MARK: - Authentication Errors

/// The errors that may occur during authentication.
public enum AuthenticationError: Int, Error
{
    // MARK: - Errors

    /// The response headers were invalid.
    case invalidHeaders

    /// The token cookie could not be found.
    case failedToFindTokenCookie

    /// The session cookie could not be found.
    case failedToFindSessionCookie
}

extension AuthenticationError: CustomNSError
{
    // MARK: - Error Domain

    /// The error domain for `AuthenticationError` values.
    public static var errorDomain: String { return "PrettyOkay.AuthenticationError" }
}

extension AuthenticationError: LocalizedError
{
    // MARK: - User Info

    /// A description of the error.
    public var errorDescription: String?
    {
        switch self
        {
        case .invalidHeaders:
            return "Invalid headers."
        case .failedToFindTokenCookie:
            return "Failed to find token cookie."
        case .failedToFindSessionCookie:
            return "Failed to find session cookie."
        }
    }
}
