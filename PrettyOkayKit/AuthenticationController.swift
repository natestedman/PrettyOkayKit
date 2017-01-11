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
import ReactiveSwift
import Shirley

// MARK: - Authenticating

/// An object that will authenticate against the Very Goods API, providing an `Authentication` value if successful.
public final class AuthenticationController
{
    // MARK: - Initialization

    /**
     Initializes an authentication controller.

     - parameter username: The username to use for authentication.
     - parameter password: The password to use for authentication.
     */
    public init(username: String, password: String)
    {
        self.username = username
        self.password = password

        self.session = NoRedirectsSession(configuration: URLSessionConfiguration.ephemeral)
            .httpResponse
            .raiseHTTPErrors()
            .mapRequests({ $0.request! })
    }

    // MARK: - Session

    /// The session to use for authentication URL requests.
    fileprivate let session: Session<AnyEndpoint, Message<HTTPURLResponse, Data>, NSError>

    // MARK: - Username and Password

    /// The username to use for authentication.
    fileprivate let username: String

    /// The password to use for authentication.
    fileprivate let password: String
}

extension AuthenticationController
{
    // MARK: - Authentication

    /// A producer for authenticating with `username` and `password`.
    public func authenticationProducer() -> SignalProducer<Authentication, NSError>
    {
        return session.outputProducer(for: CSRFEndpoint(purpose: .login))
            .delay(1, on: QueueScheduler.main)
            .flatMap(FlattenStrategy.concat, transform: { token, cookies -> SignalProducer<Authentication, NSError> in
                let endpoint = AuthenticationEndpoint(
                    username: self.username,
                    password: self.password,
                    token: token,
                    cookies: cookies
                )

                return self.session.outputProducer(for: endpoint)
            })
    }
}
