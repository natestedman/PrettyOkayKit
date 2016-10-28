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
import Foundation

// MARK: - Products

/// A product on Very Goods.
public struct Product: ModelType
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
    public let imageURL: NSURL?

    /// A URL for a medium-sized image of the product.
    public let mediumImageURL: NSURL?

    /// The URL for the original image URL, off of Very Goods.
    public let originalImageURL: NSURL?
    
    // MARK: - Source Store

    /// The string to use for displaying the domain the product was added from.
    public let displayDomain: String?

    /// The domain name that the product was added from.
    public let sourceDomain: NSURL?

    /// The original source URL for the product.
    public let sourceURL: NSURL?

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

extension Product: Decodable
{
    // MARK: - Decodable
    public typealias Encoded = [String:AnyObject]

    /// Attempts to decode a `Product`.
    ///
    /// - parameter encoded: An encoded representation of a `Product`.
    ///
    /// - throws: An error encountered while decoding the `Product`.
    ///
    /// - returns: A `Product` value, if successful.
    public static func decode(encoded: Encoded) throws -> Product
    {
        return try decode(encoded, links: nil)
    }

    /// Attempts to decode a `Product`.
    ///
    /// - parameter encoded: An encoded representation of a `Product`.
    /// - parameter links:   An alternative representation of the `links` dictionary.
    ///
    /// - throws: An error encountered while decoding the `Product`.
    ///
    /// - returns: A `Product` value, if successful.
    public static func decode(encoded: Encoded, links: [String:AnyObject]?) throws -> Product
    {
        // fall back on neutral gender if not parsed correctly, gendered items are silly anyways
        let genderString: String? = try? decode(key: "gender", from: encoded)
        let gender = genderString.flatMap({ string in Gender(rawValue: string) }) ?? .Neutral

        let goodDeletePath: String? = try? decode(
            key: "href",
            from: decode(
                key: "good:delete",
                from: links ?? decode(key: "_links", from: encoded)
            )
        )

        return Product(
            identifier: try decode(key: "id", from: encoded),
            title: try decode(key: "title", from: encoded),
            formattedPrice: try decode(key: "formatted_price", from: encoded),
            gender: gender,
            imageURL: try? decodeURL(key: "image_url", from: encoded),
            mediumImageURL: try? decodeURL(key: "medium_image_url", from: encoded),
            originalImageURL: try? decodeURL(key: "orig_image_url", from: encoded),
            displayDomain: encoded["domain_for_display"] as? String,
            sourceDomain: try? decodeURL(key: "source_domain", from: encoded),
            sourceURL: try? decodeURL(key: "source_url", from: encoded),
            goodDeletePath: goodDeletePath?.removeLeadingCharacter
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
