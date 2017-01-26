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
import ReactiveSwift

// MARK: - Products

/// A product on Very Goods.
public struct Product: ModelType, Equatable
{
    // MARK: - Model

    /// The product's identifier, required for conformance with `ModelType`.
    public let identifier: ModelIdentifier
    
    // MARK: - Metadata

    /// The product's title.
    public let title: String

    /// A formatted version of the product's price.
    public let formattedPrice: String

    /// The gender associated with the product.
    public let gender: Gender
    
    // MARK: - Images

    /// A URL for an image of the product.
    public let imageURL: URL?

    /// A URL for a medium-sized image of the product.
    public let mediumImageURL: URL?

    /// The URL for the original image URL, off of Very Goods.
    public let originalImageURL: URL?
    
    // MARK: - Source Store

    /// The string to use for displaying the domain the product was added from.
    public let displayDomain: String?

    /// The domain name that the product was added from.
    public let sourceDomain: URL?

    /// The original source URL for the product.
    public let sourceURL: URL?

    // MARK: - State

    /// The path to delete the product from the user's goods, if applicable.
    public let goodDeletePath: String?

    /// Whether or not the product is in the current user's goods. If the request did not include authentication data,
    /// this value will always be `false`.
    public var inYourGoods: Bool
    {
        return goodDeletePath != nil
    }
}

extension Product: Decoding
{
    // MARK: - Decoding

    /// Attempts to decode a `Product`.
    ///
    /// - parameter encoded: An encoded representation of a `Product`.
    ///
    /// - throws: An error encountered while decoding the `Product`.
    ///
    /// - returns: A `Product` value, if successful.
    public init(encoded: [String : Any]) throws
    {
        try self.init(encoded: encoded, links: nil)
    }

    /// Attempts to decode a `Product`.
    ///
    /// - parameter encoded: An encoded representation of a `Product`.
    /// - parameter links:   An alternative representation of the `links` dictionary.
    ///
    /// - throws: An error encountered while decoding the `Product`.
    ///
    /// - returns: A `Product` value, if successful.
    public init(encoded: [String : Any], links: [String : Any]?) throws
    {
        // fall back on neutral gender if not parsed correctly, gendered items are silly anyways
        let genderString: String? = try? encoded.decode("gender")
        let gender = genderString.flatMap({ Gender(rawValue: $0) }) ?? .neutral

        // if this is a product associated with a `Good`, determine its deletion path
        let linksToUse: [String:Any]? = try? links ?? encoded.decode("_links")
        let goodDeletePath: String?? = try? linksToUse?.sub("good:delete").decode("href")

        self.init(
            identifier: try encoded.decode("id"),
            title: try encoded.decode("title"),
            formattedPrice: try encoded.decode("formatted_price"),
            gender: gender,
            imageURL: try? encoded.decodeURL("image_url"),
            mediumImageURL: try? encoded.decodeURL("medium_image_url"),
            originalImageURL: try? encoded.decodeURL("orig_image_url"),
            displayDomain: encoded["domain_for_display"] as? String,
            sourceDomain: try? encoded.decodeURL("source_domain"),
            sourceURL: try? encoded.decodeURL("source_url"),
            goodDeletePath: goodDeletePath??.removeLeadingCharacter
        )
    }
}

extension String
{
    var removeLeadingCharacter: String
    {
        return String(characters.dropFirst())
    }
}

/// Equates two `Product` values.
///
/// - parameter lhs: The first product value.
/// - parameter rhs: The second product value.
///
/// - returns: If the values are equal, `true`.

public func ==(lhs: Product, rhs: Product) -> Bool
{
    return lhs.identifier == rhs.identifier
        && lhs.title == rhs.title
        && lhs.formattedPrice == rhs.formattedPrice
        && lhs.gender == rhs.gender
        && lhs.imageURL == rhs.imageURL
        && lhs.mediumImageURL == rhs.mediumImageURL
        && lhs.originalImageURL == rhs.originalImageURL
        && lhs.displayDomain == rhs.displayDomain
        && lhs.sourceDomain == rhs.sourceDomain
        && lhs.goodDeletePath == rhs.goodDeletePath
}
