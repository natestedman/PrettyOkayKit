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

import Foundation

// MARK: - Authentication

/// A protocol base for `Authentication`.
public protocol AuthenticationType
{
    // MARK: - Initialization

    /// Initializes an authentication value.
    ///
    /// - parameter username: The username associated with the session.
    /// - parameter token:    The authentication cookie.
    /// - parameter session:  The session cookie.
    init(username: String, token: NSHTTPCookie, session: NSHTTPCookie)

    // MARK: - Properties

    /// The username associated with the session.
    var username: String { get }

    /// The authentication cookie.
    var token: NSHTTPCookie { get }

    /// The session cookie.
    var session: NSHTTPCookie { get }
}

/// An authenticated session on Very Goods.
public struct Authentication: Equatable, AuthenticationType
{
    // MARK: - Initialization

    /// Initializes an authentication value.
    ///
    /// - parameter username: The username associated with the session.
    /// - parameter token:    The authentication cookie.
    /// - parameter session:  The session cookie.
    public init(username: String, token: NSHTTPCookie, session: NSHTTPCookie)
    {
        self.username = username
        self.token = token
        self.session = session
    }

    // MARK: - Properties

    /// The username associated with the session.
    public let username: String

    /// The authentication cookie.
    public let token: NSHTTPCookie

    /// The session cookie
    public let session: NSHTTPCookie
}

extension Authentication
{
    // MARK: - URL Requests

    /**
     Applies the authentication to the specified mutable URL requests.

     - parameter URLRequest: The URL request.
     */
    public func applyToMutableURLRequest(URLRequest: NSMutableURLRequest)
    {
        for (header, value) in NSHTTPCookie.requestHeaderFieldsWithCookies([token, session])
        {
            URLRequest.setValue(value, forHTTPHeaderField: header)
        }
    }
}

// MARK: - Equatable

/// Equates two `Authentication` values.
///
/// - parameter lhs: The first authentication value.
/// - parameter rhs: The second authentication value.
///
/// - returns: If the values are equal, `true`.
@warn_unused_result
public func ==(lhs: Authentication, rhs: Authentication) -> Bool
{
    return lhs.token.isEqual(rhs.token) && lhs.session.isEqual(rhs.token)
}

extension Authentication: Decoding, Encoding
{
    // MARK: - Coding
    /// Attempts to decode an authentication value.
    ///
    /// - parameter encoded: The encoded representation.
    ///
    /// - throws: Errors encounted while decoding.
    ///
    /// - returns: A decoded authentication value.
    public init(encoded: [String : AnyObject]) throws
    {
        guard let token = NSHTTPCookie(properties: try encoded.decode("token")) else {
            throw DecodeKeyError(key: "token")
        }

        guard let session = NSHTTPCookie(properties: try encoded.decode("session")) else {
            throw DecodeKeyError(key: "session")
        }

        self.init(username: try encoded.decode("username"), token: token, session: session)
    }

    /// Encodes the authentication value.
    public var encoded: [String : AnyObject]
    {
        return [
            "username": username,
            "token": token.properties ?? [:],
            "session": session.properties ?? [:]
        ]
    }
}
