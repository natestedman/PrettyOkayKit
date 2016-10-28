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

extension APIClient
{
    // MARK: - Loading Product Relations

    /// A producer for a product's relations.
    ///
    /// - parameter identifier: The product identifier to load relations for.
    public func productRelationsProducer(identifier identifier: ModelIdentifier)
        -> SignalProducer<ProductRelations, NSError>
    {
        return dataSession.producerForEndpoint(ProductRelationsEndpoint(productIdentifier: identifier))
    }
}

extension APIClient
{
    // MARK: - Page Load Strategies

    /**
     A utility for creating load strategies for endpoint types that use a `ModelPage` for pagination.

     - parameter limit:        The expected number of elements per page.
     - parameter makeEndpoint: A function to build an endpoint value.
     */
    private func modelPageLoadStrategy
        <Model: ModelType, Endpoint: BaseURLEndpointType where Endpoint: ProcessingType, Endpoint.Input == AnyObject, Endpoint.Output == [Model], Endpoint.Error == NSError>
        (limit limit: Int, makeEndpoint: (LoadRequest<Model>, ModelPage) -> Endpoint)
        -> StrategyArrayLoader<Model, NSError>.LoadStrategy
    {
        return { request in
            switch ModelPage.pageForLoadRequest(request)
            {
            case .Success(let page):
                return self.endpointSession
                    .producerForEndpoint(makeEndpoint(request, page))
                    .loadResultProducerWithRequest(request, limit: limit)

            case .Failure(let error):
                return SignalProducer(error: error)
            }
        }
    }

    /**
     A utility for creating load strategies for endpoint tpyes that use an `OffsetPage` for pagination.

     - parameter limit:        The expected number of elements per page.
     - parameter makeEndpoint: A function to build an endpoint value.
     */
    private func offsetPageLoadStrategy
        <Model: ModelType, Endpoint: BaseURLEndpointType where Endpoint: ProcessingType, Endpoint.Input == AnyObject, Endpoint.Output == [Model], Endpoint.Error == NSError>
        (limit limit: Int, makeEndpoint: (LoadRequest<Model>, OffsetPage) -> Endpoint)
        -> StrategyArrayLoader<Model, NSError>.LoadStrategy
    {
        return { request in
            let page: OffsetPage

            switch request
            {
            case .Next(let current):
                page = OffsetPage(skip: current.count)

            case .Previous(let current):
                if current.count == 0
                {
                    return SignalProducer(error: APIClientLoadingError.FirstPageNotLoaded.NSError)
                }
                else
                {
                    page = OffsetPage(skip: 0)
                }
            }

            return self.endpointSession
                .producerForEndpoint(makeEndpoint(request, page))
                .loadResultProducerWithRequest(request, limit: limit)
        }
    }

    // MARK: - Loading Model Pages

    /**
     Returns a load strategy for a user's goods.

     - parameter username:  The username to request goods for.
     - parameter filters:   The filters to apply.
     - parameter limit:     The number of goods to fetch per page.
     */
    public func goodsLoadStrategy(username username: String, filters: Filters, limit: Int)
        -> StrategyArrayLoader<Good, NSError>.LoadStrategy
    {
        return modelPageLoadStrategy(limit: limit, makeEndpoint: { request, page in
            GoodsEndpoint(username: username, filters: filters, page: page, limit: limit)
        })
    }

    /**
     Returns a load strategy for the global products list.

     - parameter filters: The filters to use.
     - parameter limit:   The number of products to fetch per page.
     */
    public func productsLoadStrategy(filters filters: Filters, limit: Int)
        -> StrategyArrayLoader<Product, NSError>.LoadStrategy
    {
        return modelPageLoadStrategy(limit: limit, makeEndpoint: { request, page in
            ProductsEndpoint(filters: filters, page: page, limit: limit)
        })
    }

    /**
     Returns a load strategy for the global users list.

     - parameter order: The order in which users should be loaded.
     - parameter limit: The number of users to fetch per page.
     */
    public func usersLoadStrategy(order order: Order, limit: Int) -> StrategyArrayLoader<User, NSError>.LoadStrategy
    {
        return offsetPageLoadStrategy(limit: limit, makeEndpoint: { request, page in
            UsersEndpoint(order: order, page: page, limit: limit)
        })
    }

    /**
     Returns an array loader for a search query.

     - parameter query: The query.
     - parameter limit: The number of products to fetch per page.
     */
    public func searchArrayLoader(query query: String, limit: Int) -> AnyArrayLoader<Product, NSError>
    {
        let loader = InfoStrategyArrayLoader<Product, Int, NSError>(
            nextInfo: 1,
            previousInfo: 0,
            load: { request in
                let page = IndexPage(index: request.info)
                let endpoint = SearchEndpoint(query: query, page: page, limit: limit)

                return self.endpointSession.producerForEndpoint(endpoint).map({ products in
                    InfoLoadResult(
                        elements: products,
                        nextPageHasMore: products.count == limit ? .DoNotReplace : .Replace(false),
                        nextPageInfo: .Replace(page.index + 1)
                    )
                })
            }
        )

        return AnyArrayLoader(loader)
    }
}

// MARK: - ArrayType
private protocol ArrayType
{
    associatedtype Element
    var array: [Element] { get }
    var count: Int { get }
}

extension Array: ArrayType
{
    var array: [Element]
    {
        return self
    }
}

// MARK: - SignalProducer Extension
extension SignalProducerType where Value: ArrayType
{
    private func loadResultProducerWithRequest(request: LoadRequest<Value.Element>, limit: Int)
        -> SignalProducer<LoadResult<Value.Element>, Error>
    {
        return map({ elements in
            LoadResult(
                elements: elements.array,
                nextPageHasMore: (request.isNext && elements.count < limit) ? .Replace(false) : .DoNotReplace,
                previousPageHasMore: .DoNotReplace
            )
        })
    }
}
