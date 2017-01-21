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
import ReactiveSwift
import Shirley
import enum Result.NoError

/// A client for the Very Goods API.
public final class APIClient
{
    // MARK: - Initialization

    /// Initializes an API client.
    ///
    /// - parameter authentication: The authentication to use for the client.
    /// - parameter log: A logging function for requests and errors.
    public init(authentication: Authentication?, log: @escaping (String) -> () = { _ in })
    {
        self.authentication = authentication

        // session setup
        let dataSession = urlSession.httpResponse.mapRequests({ (request: URLRequest) in
            var mutable = request
            authentication?.apply(to: &mutable)
            return mutable
        })

        let loggingSession = Session { request in
            dataSession.producer(for: request)
                .on(started: { log("Sending \(request.logDescription)") })
                .on(value: { log("Response \($0.response.statusCode) \(request.url!.absoluteString)") })
        }.raiseHTTPErrors { response, data in
            let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "invalid" as NSString
            return ["Response String": str]
        }

        self.dataSession = loggingSession
        self.endpointSession = loggingSession.json().body.mapRequests({ (endpoint: AnyBaseURLEndpoint) in
            endpoint.request(baseURL: URL(string: "https://verygoods.co/site-api-0.1/")!)!
        })

        // CSRF setup
        csrfToken = Property(
            initial: nil,
            then: authentication.map({ authentication in
                SignalProducer(value: ())
                .concat(timer(interval: .seconds(3600), on: QueueScheduler.main).map({ _ in () }))

                // request a CSRF token
                .flatMap(.latest, transform: { _ -> SignalProducer<String?, NoError> in
                    loggingSession.endpointProducer(for: CSRFEndpoint(purpose: .authenticated(authentication)))
                        .map({ $0.token })
                        .flatMapError({ _ in SignalProducer.empty })
                })
            }) ?? SignalProducer.empty
        )
    }

    // MARK: - Sessions

    /// The backing session for derived sessions.
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)

    /// A session for loading data.
    let dataSession: Session<URLRequest, Message<HTTPURLResponse, Data>, NSError>

    /// A session for using endpoint values to load JSON objects.
    let endpointSession: Session<AnyBaseURLEndpoint, Any, NSError>

    // MARK: - Authentication

    /// The authentication value for this API client.
    public let authentication: Authentication?

    // MARK: - CSRF

    /// Destructive actions against the Very Goods API require a CSRF token. If authenticated, the client will
    /// automatically obtain one periodically, and place it in this property.
    let csrfToken: Property<String?>
}

extension URLRequest
{
    fileprivate var logDescription: String
    {
        if let headers = allHTTPHeaderFields
        {
            return "\(httpMethod!) \(url!.absoluteString) \(headers)"
        }
        else
        {
            return "\(httpMethod!) \(url!.absoluteString)"
        }
    }
}
