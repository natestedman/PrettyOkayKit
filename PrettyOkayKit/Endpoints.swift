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
import Foundation
import Result

// MARK: - Processing Type
protocol ResultProcessing
{
    associatedtype Input
    associatedtype Output
    associatedtype Error: Swift.Error

    func result(for input: Input) -> Result<Output, Error>
}

extension ResultProcessing where Output == ()
{
    func result(for input: Input) -> Result<Output, Error>
    {
        return .success(())
    }
}

protocol DecodableEmbeddedArrayResultProcessing: ResultProcessing
{
    associatedtype Embedded: Decoding

    var embeddedKey: String { get }
}

extension DecodableEmbeddedArrayResultProcessing where Input == Any, Output == [Embedded]
{
    func result(for input: Input) -> Result<Output, NSError>
    {
        guard let encoded = (input as? [String:Any])?["_embedded"] as? [String:Any] else {
            return .failure(DecodeKeyError(key: "_embedded") as NSError)
        }

        guard let array = encoded[embeddedKey] as? [Any] else {
            return .failure(DecodeKeyError(key: embeddedKey) as NSError)
        }

        do
        {
            return .success(try array.map(Embedded.init))
        }
        catch let error as NSError
        {
            return .failure(error)
        }
    }
}

// MARK: - Paginated Endpoints
protocol PageEndpoint: BaseURLEndpoint, HTTPMethodProvider
{
    /// The page type for this endpoint.
    associatedtype Page: QueryItemsRepresentable

    /// The page for this endpoint.
    var page: Page { get }

    /// The maximum number of items to load.
    var limit: Int { get }
}

extension PageEndpoint where Self: HTTPMethodProvider
{
    var httpMethod: HTTPMethod { return .get }
}

extension PageEndpoint
{
    /// The basic query items needed to load this endpoint.
    var baseQueryItems: [URLQueryItem]
    {
        return [URLQueryItem(name: "limit", value: "\(limit)")] + page.queryItems
    }
}

extension PageEndpoint where Self: QueryItemsProvider
{
    /// The query items for this endpoint.
    var queryItems: [URLQueryItem]
    {
        return baseQueryItems
    }
}

// MARK: - Goods Endpoints
struct GoodsEndpoint
{
    /// The username of the user whose goods the endpoint should load.
    let username: String

    /// The filters to apply.
    let filters: Filters

    /// The page for this endpoint.
    let page: ModelPage

    /// The maximum number of goods to load.
    let limit: Int
}

extension GoodsEndpoint: PageEndpoint, QueryItemsProvider, RelativeURLStringProvider
{
    /// `"users/[username]/goods"`.
    var relativeURLString: String { return "users/\(username.pathEscaped)/goods" }

    /// The query items for the goods endpoint.
    var queryItems: [URLQueryItem]
    {
        return baseQueryItems + filters.queryItems
    }
}

extension GoodsEndpoint: DecodableEmbeddedArrayResultProcessing
{
    typealias Input = Any
    typealias Output = [Embedded]
    typealias Error = NSError
    typealias Embedded = Good

    var embeddedKey: String { return "goods" }
}

// MARK: - Product Endpoints
struct ProductsEndpoint
{
    /// The filters to use.
    let filters: Filters

    /// The page for this endpoint.
    let page: ModelPage

    /// The maximum number of products to load.
    let limit: Int
}

extension ProductsEndpoint: PageEndpoint, QueryItemsProvider, RelativeURLStringProvider
{
    /// `"products"`.
    var relativeURLString: String { return "products" }

    /// The query items for this endpoint.
    var queryItems: [URLQueryItem]
    {
        return baseQueryItems + filters.queryItems
    }
}

extension ProductsEndpoint: DecodableEmbeddedArrayResultProcessing
{
    typealias Input = Any
    typealias Output = [Embedded]
    typealias Error = NSError
    typealias Embedded = Product

    var embeddedKey: String { return "products" }
}

// MARK: - Search Endpoints
struct SearchEndpoint
{
    let query: String
    let page: IndexPage
    let limit: Int
}

extension SearchEndpoint: PageEndpoint, QueryItemsProvider, RelativeURLStringProvider
{
    /// `products`.
    var relativeURLString: String { return "products" }

    /// The query items for this endpoint.
    var queryItems: [URLQueryItem]
    {
        return baseQueryItems + [URLQueryItem(name: "q", value: query)]
    }
}

extension SearchEndpoint: DecodableEmbeddedArrayResultProcessing
{
    typealias Input = Any
    typealias Output = [Embedded]
    typealias Error = NSError
    typealias Embedded = Product

    var embeddedKey: String { return "products" }
}

// MARK: - User Endpoints

/// An endpoint for loading the global list of users.
struct UsersEndpoint
{
    /// The order to load users in.
    let order: Order

    /// The page for this endpoint.
    let page: OffsetPage

    /// The maximum number of users to load.
    let limit: Int
}

extension UsersEndpoint: PageEndpoint, QueryItemsProvider, RelativeURLStringProvider
{
    /// `"users"`.
    var relativeURLString: String { return "users" }

    /// The query items for this endpoint.
    var queryItems: [URLQueryItem]
    {
        return baseQueryItems + order.queryItems
    }
}

extension UsersEndpoint: DecodableEmbeddedArrayResultProcessing
{
    typealias Input = Any
    typealias Output = [Embedded]
    typealias Error = NSError
    typealias Embedded = User

    var embeddedKey: String { return "users" }
}
