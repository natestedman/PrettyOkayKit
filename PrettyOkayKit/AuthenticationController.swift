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
import ReactiveCocoa
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

        self.session = NoRedirectsSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
            .HTTPSession()
            .raiseHTTPErrors()
            .mapRequests({ request in request.request! })
    }

    // MARK: - Session

    /// The session to use for authentication URL requests.
    private let session: Session<AnyEndpoint, Message<NSHTTPURLResponse, NSData>, NSError>

    // MARK: - Username and Password

    /// The username to use for authentication.
    private let username: String

    /// The password to use for authentication.
    private let password: String
}

extension AuthenticationController
{
    // MARK: - Authentication

    /// A producer for authenticating with `username` and `password`.
    public func authenticationProducer() -> SignalProducer<Authentication, NSError>
    {
        return session.outputProducerForRequest(CSRFEndpoint(purpose: .Login))
            .delay(1, onScheduler: QueueScheduler.mainQueueScheduler)
            .map({ token, cookies in
                AuthenticationEndpoint(username: self.username, password: self.password, token: token, cookies: cookies)
            })
            .flatMap(.Concat, transform: self.session.outputProducerForRequest)
    }
}
