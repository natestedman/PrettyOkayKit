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

extension Good: Decoding
{
    // MARK: - Decoding

    /// Attempts to decode a `Good`.
    ///
    /// - parameter encoded: An encoded representation of a `Good`.
    ///
    /// - throws: An error encountered while decoding the `Good`.
    ///
    /// - returns: A `Good` value, if successful.
    public init(encoded: [String : Any]) throws
    {
        let embedded = try encoded.sub("_embedded")
        let links = try encoded.sub("_links")

        self.init(
            identifier: try encoded.decode("id"),
            product: try Product(encoded: embedded.decode("product"), links: links),
            owner: try User(encoded: embedded.decode("owner"))
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

/// Equates two `Good` values.
///
/// - parameter lhs: The first good value.
/// - parameter rhs: The second good value.
///
/// - returns: If the values are equal, `true`.

public func ==(lhs: Good, rhs: Good) -> Bool
{
    return lhs.identifier == rhs.identifier && lhs.product == rhs.product && lhs.owner == rhs.owner
}
