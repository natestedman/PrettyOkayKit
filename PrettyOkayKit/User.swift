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

// MARK: - Users

/// A user on Very Goods.
public struct User: ModelType, Equatable
{
    // MARK: - Model

    /// The user's identifier, required for conformance with `ModelType`.
    public let identifier: ModelIdentifier
    
    // MARK: - Metadata

    /// The user's Very Goods username.
    public let username: String

    /// The user's "real name", if any.
    public let name: String?

    /// The user's biography text, if any.
    public let biography: String?

    /// The user's location, if any.
    public let location: String?

    /// The user's personal website URL.
    public let URL: Foundation.URL?
    
    // MARK: - Avatar

    /// The URL for the user's avatar.
    public let avatarURL: Foundation.URL?

    /// The URL for the centered 126-pixel version of the user's avatar.
    public let avatarURLCentered126: Foundation.URL?
    
    // MARK: - Cover

    /// The URL for the user's cover image.
    public let coverURL: Foundation.URL?

    /// The URL for the large version of the user's cover image.
    public let coverLargeURL: Foundation.URL?

    /// The URL for the thumbnail version of the user's cover image.
    public let coverThumbURL: Foundation.URL?
    
    // MARK: - Goods

    /// The number of goods the user has added to his or her profile.
    public let goodsCount: Int
}

extension User: Decoding
{
    // MARK: - Decoding

    /// Attempts to decode a `User`.
    ///
    /// - parameter encoded: An encoded representation of a `User`.
    ///
    /// - throws: An error encountered while decoding the `User`.
    ///
    /// - returns: A `User` value, if successful.
    public init(encoded: [String : Any]) throws
    {
        self.init(
            identifier: try encoded.decode("id"),
            username: try encoded.decode("username"),
            name: encoded["name"] as? String,
            biography: encoded["bio"] as? String,
            location: encoded["location"] as? String,
            URL: try? encoded.decodeURL("url"),
            avatarURL: try? encoded.decodeURL("avatar_url"),
            avatarURLCentered126: try? encoded.decodeURL("avatar_url_centered_126"),
            coverURL: try? encoded.decodeURL("cover_image"),
            coverLargeURL: try? encoded.decodeURL("cover_image_big_url"),
            coverThumbURL: try? encoded.decodeURL("cover_image_thumb_url"),
            goodsCount: try encoded.decode("good_count")
        )
    }
}

extension User: CustomStringConvertible
{
    public var description: String
    {
        return "User \(self.identifier) (@\(self.username))"
    }
}

/// Equates two `User` values.
///
/// - parameter lhs: The first user value.
/// - parameter rhs: The second user value.
///
/// - returns: If the values are equal, `true`.

public func ==(lhs: User, rhs: User) -> Bool
{
    return lhs.identifier == rhs.identifier
        && lhs.username == rhs.username
        && lhs.name == rhs.name
        && lhs.biography == rhs.biography
        && lhs.location == rhs.location
        && lhs.URL == rhs.URL
        && lhs.avatarURL == rhs.avatarURL
        && lhs.avatarURLCentered126 == rhs.avatarURLCentered126
        && lhs.coverURL == rhs.coverURL
        && lhs.coverLargeURL == rhs.coverLargeURL
        && lhs.coverThumbURL == rhs.coverThumbURL
        && lhs.goodsCount == rhs.goodsCount
}
