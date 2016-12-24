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

import Foundation

// MARK: - Product Relations

/// A structure describing models associated with a `Product`.
public struct ProductRelations: Equatable
{
    // MARK: - Initialization

    /**
     Initializes a product details value.

     - parameter relatedProducts: The related products for the product.
     - parameter users:           The users that have added the product to their goods.
     */
    public init(relatedProducts: [Product], users: [User])
    {
        self.relatedProducts = relatedProducts
        self.users = users
    }

    // MARK: - Properties

    /// The related products for the product.
    public let relatedProducts: [Product]

    /// The users that have added the product to their goods.
    public let users: [User]
}

/// Equates two `ProductRelations` values.
///
/// - parameter lhs: The first product relations value.
/// - parameter rhs: The second product relations value.
///
/// - returns: If the values are equal, `true`.
@warn_unused_result
public func ==(lhs: ProductRelations, rhs: ProductRelations) -> Bool
{
    return lhs.relatedProducts == rhs.relatedProducts && lhs.users == rhs.users
}
