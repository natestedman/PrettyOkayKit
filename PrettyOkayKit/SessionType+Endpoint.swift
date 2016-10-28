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

import ArrayLoader
import Endpoint
import ReactiveCocoa
import Shirley

extension SessionType where Request == AnyBaseURLEndpoint
{
    // MARK: - Signal Producers
    func producerForEndpoint<Endpoint: BaseURLEndpointType where Endpoint: ProcessingType, Endpoint.Input == Value, Endpoint.Error == Error>
        (endpoint: Endpoint) -> SignalProducer<Endpoint.Output, Error>
    {
        return producerForRequest(AnyBaseURLEndpoint(endpoint)).flatMap(.Concat, transform: { value in
            SignalProducer(result: endpoint.resultForInput(value))
        })
    }
}

extension SessionType where Request == NSURLRequest
{
    func producerForEndpoint<Endpoint: EndpointType where Endpoint: ProcessingType, Endpoint.Input == Value, Endpoint.Error == Error>
        (endpoint: Endpoint) -> SignalProducer<Endpoint.Output, Error>
    {
        return producerForRequest(endpoint.request!).flatMap(.Concat, transform: { value in
            SignalProducer(result: endpoint.resultForInput(value))
        })
    }
}

/// `SessionType` is extended to provide endpoint and load strategy support.
extension SessionType where Request == AnyBaseURLEndpoint, Value == AnyObject, Error == NSError
{
    // MARK: - Endpoints

    /// Creates a signal producer for the specified endpoint.
    ///
    /// - parameter endpoint: The endpoint.
    func producerForEndpoint
        <Endpoint: BaseURLEndpointType where Endpoint: ProcessingType, Endpoint.Input == AnyObject, Endpoint.Error == Error>
        (endpoint: Endpoint) -> SignalProducer<Endpoint.Output, NSError>
    {
        return producerForRequest(AnyBaseURLEndpoint(endpoint)).flatMap(.Concat, transform: { JSON in
            SignalProducer(result: endpoint.resultForInput(JSON))
        })
    }
}

extension SessionType where Request == AnyEndpoint
{
    func outputProducerForRequest
        <Endpoint: EndpointType where Endpoint: ProcessingType, Endpoint.Input == Value, Endpoint.Error == Error>
        (request: Endpoint) -> SignalProducer<Endpoint.Output, Error>
    {
        return producerForRequest(AnyEndpoint(request)).flatMap(.Concat, transform: { input in
            SignalProducer(result: request.resultForInput(input))
        })
    }
}
