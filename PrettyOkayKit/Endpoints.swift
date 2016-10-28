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
import Codable
import Endpoint
import Foundation
import NSErrorRepresentable
import Result

// MARK: - Processing Type
protocol ProcessingType
{
    associatedtype Input
    associatedtype Output
    associatedtype Error: ErrorType

    func resultForInput(input: Input) -> Result<Output, Error>
}

extension ProcessingType where Output == ()
{
    func resultForInput(input: Input) -> Result<Output, Error>
    {
        return .Success(())
    }
}

protocol DecodableEmbeddedArrayProcessingType: ProcessingType
{
    associatedtype Embedded: Decodable

    var embeddedKey: String { get }
}

extension DecodableEmbeddedArrayProcessingType where Input == AnyObject, Output == [Embedded]
{
    func resultForInput(input: Input) -> Result<Output, NSError>
    {
        guard let encoded = (input as? [String:AnyObject])?["_embedded"] as? [String:AnyObject] else {
            return .Failure(DecodeKeyError(key: "_embedded").NSError)
        }

        guard let array = encoded[embeddedKey] as? [AnyObject] else {
            return .Failure(DecodeKeyError(key: embeddedKey).NSError)
        }

        do
        {
            return .Success(try rethrowNSError(try array.map(Embedded.decodeAny)))
        }
        catch let error as NSError
        {
            return .Failure(error)
        }
    }
}

// MARK: - Paginated Endpoints
protocol PageEndpointType: BaseURLEndpointType, MethodProviderType
{
    /// The page type for this endpoint.
    associatedtype Page: QueryItemsRepresentable

    /// The page for this endpoint.
    var page: Page { get }

    /// The maximum number of items to load.
    var limit: Int { get }
}

extension PageEndpointType where Self: MethodProviderType
{
    var method: Endpoint.Method { return .Get }
}

extension PageEndpointType
{
    /// The basic query items needed to load this endpoint.
    var baseQueryItems: [NSURLQueryItem]
    {
        return [NSURLQueryItem(name: "limit", value: "\(limit)")] + page.queryItems
    }
}

extension PageEndpointType where Self: QueryItemsProviderType
{
    /// The query items for this endpoint.
    var queryItems: [NSURLQueryItem]
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

extension GoodsEndpoint: PageEndpointType, QueryItemsProviderType, RelativeURLStringProviderType
{
    /// `"users/[username]/goods"`.
    var relativeURLString: String { return "users/\(username.pathEscaped)/goods" }

    /// The query items for the goods endpoint.
    var queryItems: [NSURLQueryItem]
    {
        return baseQueryItems + filters.queryItems
    }
}

extension GoodsEndpoint: DecodableEmbeddedArrayProcessingType
{
    typealias Input = AnyObject
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

extension ProductsEndpoint: PageEndpointType, QueryItemsProviderType, RelativeURLStringProviderType
{
    /// `"products"`.
    var relativeURLString: String { return "products" }

    /// The query items for this endpoint.
    var queryItems: [NSURLQueryItem]
    {
        return baseQueryItems + filters.queryItems
    }
}

extension ProductsEndpoint: DecodableEmbeddedArrayProcessingType
{
    typealias Input = AnyObject
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

extension SearchEndpoint: PageEndpointType, QueryItemsProviderType, RelativeURLStringProviderType
{
    /// `products`.
    var relativeURLString: String { return "products" }

    /// The query items for this endpoint.
    var queryItems: [NSURLQueryItem]
    {
        return baseQueryItems + [NSURLQueryItem(name: "q", value: query)]
    }
}

extension SearchEndpoint: DecodableEmbeddedArrayProcessingType
{
    typealias Input = AnyObject
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

extension UsersEndpoint: PageEndpointType, QueryItemsProviderType, RelativeURLStringProviderType
{
    /// `"users"`.
    var relativeURLString: String { return "users" }

    /// The query items for this endpoint.
    var queryItems: [NSURLQueryItem]
    {
        return baseQueryItems + order.queryItems
    }
}

extension UsersEndpoint: DecodableEmbeddedArrayProcessingType
{
    typealias Input = AnyObject
    typealias Output = [Embedded]
    typealias Error = NSError
    typealias Embedded = User

    var embeddedKey: String { return "users" }
}
