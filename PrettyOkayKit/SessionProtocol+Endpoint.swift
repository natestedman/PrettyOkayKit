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
import ReactiveSwift
import Shirley

extension SessionProtocol where Request == AnyBaseURLEndpoint
{
    // MARK: - Signal Producers
    func baseURLEndpointProducer<Endpoint: BaseURLEndpoint>(for endpoint: Endpoint)
        -> SignalProducer<Endpoint.Output, Error>
        where Endpoint: ResultProcessing, Endpoint.Input == Value, Endpoint.Error == Error
    {
        return producer(for: AnyBaseURLEndpoint(endpoint)).flatMap(.concat, transform: { value in
            SignalProducer(result: endpoint.result(for: value))
        })
    }
}

extension SessionProtocol where Request == URLRequest
{
    func endpointProducer<EndpointValue: Endpoint>(for endpoint: EndpointValue)
        -> SignalProducer<EndpointValue.Output, Error>
        where EndpointValue: ResultProcessing, EndpointValue.Input == Value, EndpointValue.Error == Error
    {
        return producer(for: endpoint.request!).flatMap(.concat, transform: { value in
            SignalProducer(result: endpoint.result(for: value))
        })
    }
}

extension SessionProtocol where Request == AnyEndpoint
{
    func outputProducer<EndpointValue: Endpoint>(for request: EndpointValue)
        -> SignalProducer<EndpointValue.Output, Error>
        where EndpointValue: ResultProcessing, EndpointValue.Input == Value, EndpointValue.Error == Error
    {
        return producer(for: AnyEndpoint(request)).flatMap(.concat, transform: { input in
            SignalProducer(result: request.result(for: input))
        })
    }
}
