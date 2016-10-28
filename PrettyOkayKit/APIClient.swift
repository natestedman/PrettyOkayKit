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
import ReactiveCocoa
import Shirley
import enum Result.NoError

/// A client for the Very Goods API.
public final class APIClient
{
    // MARK: - Initialization

    /// Initializes an API client.
    ///
    /// - parameter authentication: The authentication to use for the client.
    public init(authentication: Authentication?)
    {
        self.authentication = authentication

        // session setup
        let dataSession = URLSession.HTTPSession().mapRequests({ (request: NSURLRequest) in
            let mutable = (request as? NSMutableURLRequest) ?? request.mutableCopy() as! NSMutableURLRequest
            authentication?.applyToMutableURLRequest(mutable)
            return mutable
        })

        let loggingSession = Session { request in
            dataSession.producerForRequest(request)
                .on(started: { print("Sending \(request.logDescription)") })
                .on(next: { print("Response \($0.response.statusCode) \(request.URL!.absoluteString)") })
        }.raiseHTTPErrors { response, data in
            let str = NSString(data: data, encoding: NSUTF8StringEncoding) ?? "invalid"
            return ["Response String": str]
        }

        self.dataSession = loggingSession
        self.endpointSession = loggingSession.JSONSession().bodySession().mapRequests({ endpoint in
            endpoint.requestWithBaseURL(NSURL(string: "https://verygoods.co/site-api-0.1/")!)!
        })

        // CSRF setup
        let CSRFSession = loggingSession.mapRequests({ (endpoint: AnyEndpoint) in endpoint.request! })

        CSRFToken = AnyProperty(
            initialValue: nil,
            producer: authentication.map({ authentication in
                SignalProducer(value: ())
                .concat(timer(3600, onScheduler: QueueScheduler.mainQueueScheduler).map({ _ in () }))

                // request a CSRF token
                .flatMap(.Latest, transform: { _ -> SignalProducer<String, NoError> in
                    CSRFSession.outputProducerForRequest(CSRFEndpoint(purpose: .Authenticated(authentication)))
                        .map({ $0.token })
                        .flatMapError({ _ in SignalProducer.empty })
                })
                .map({ $0 })
            }) ?? SignalProducer.empty
        )
    }

    // MARK: - Sessions

    /// The backing session for derived sessions.
    let URLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

    /// A session for loading data.
    let dataSession: Session<NSURLRequest, Message<NSHTTPURLResponse, NSData>, NSError>

    /// A session for using endpoint values to load JSON objects.
    let endpointSession: Session<AnyBaseURLEndpoint, AnyObject, NSError>

    // MARK: - Authentication

    /// The authentication value for this API client.
    public let authentication: Authentication?

    // MARK: - CSRF

    /// Destructive actions against the Very Goods API require a CSRF token. If authenticated, the client will
    /// automatically obtain one periodically, and place it in this property.
    let CSRFToken: AnyProperty<String?>
}

extension NSURLRequest
{
    private var logDescription: String
    {
        if let headers = allHTTPHeaderFields
        {
            return "\(HTTPMethod!) \(URL!.absoluteString) \(headers)"
        }
        else
        {
            return "\(HTTPMethod!) \(URL!.absoluteString)"
        }
    }
}
