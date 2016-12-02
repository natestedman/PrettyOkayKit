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

import Codable

// MARK: - Goods

/// A relationship between a `User` and a `Product`.
public struct Good: ModelType, Equatable
{
    // MARK: - Model

    /// The good's identifier, required for conformance with `ModelType`.
    public let identifier: ModelIdentifier
    
    // MARK: - Submodels

    /// The product associated with the good.
    public let product: Product

    /// The user associated with the good.
    public let owner: User
}

extension Good: Decodable
{
    // MARK: - Decodable
    public typealias Encoded = [String:AnyObject]

    /// Attempts to decode a `Good`.
    ///
    /// - parameter encoded: An encoded representation of a `Good`.
    ///
    /// - throws: An error encountered while decoding the `Good`.
    ///
    /// - returns: A `Good` value, if successful.
    public static func decode(encoded: Encoded) throws -> Good
    {
        let embedded: [String:AnyObject] = try decode(key: "_embedded", from: encoded)
        let links: [String:AnyObject] = try decode(key: "_links", from: encoded)
        
        return Good(
            identifier: try decode(key: "id", from: encoded),
            product: try Product.decode(try decode(key: "product", from: embedded), links: links),
            owner: try User.decode(try decode(key: "owner", from: embedded))
        )
    }
}

extension Good: CustomStringConvertible
{
    public var description: String
    {
        return "Good (\(product)) -> (\(owner))"
    }
}

@warn_unused_result
public func ==(lhs: Good, rhs: Good) -> Bool
{
    return lhs.identifier == rhs.identifier && lhs.product == rhs.product && lhs.owner == rhs.owner
}
