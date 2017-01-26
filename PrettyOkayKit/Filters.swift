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

// MARK: - Filters

/// The filters that can be applied to a list of products.
public struct Filters: Equatable
{
    // MARK: - Initialization

    /**
     Initializes a `Filters` value.

     - parameter price:    The price filters, if any.
     - parameter gender:   The gender filters, if any.
     - parameter category: The category filters, if any.
     */
    public init(price: Set<Price> = Set(), gender: Set<Gender> = Set(), category: Set<Category> = Set())
    {
        self.price = price
        self.gender = gender
        self.category = category
    }

    /// A `Filters` with all component values selected.
    public static var all: Filters
    {
        return Filters(price: Set(Price.all), gender: Set(Gender.all), category: Set(Category.all))
    }

    // MARK: - Filters

    /// The price filters.
    public let price: Set<Price>

    /// The gender filters.
    public let gender: Set<Gender>

    /// The category filters.
    public let category: Set<Category>
}

extension Filters
{
    // MARK: - Simplifying

    /// Returns a simplified version of the filters.
    ///
    /// If any of the individual filter components is a set of all possibilities, it can be replaced with an empty set
    /// for the same effect.
    public func simplified() -> Filters
    {
        return Filters(
            price: price.simplifiedSet(),
            gender: gender.simplifiedSet(),
            category: category.simplifiedSet()
        )
    }
}

/// Equates two `Filters` values.
///
/// - parameter lhs: The first filters value.
/// - parameter rhs: The second filters value.
///
/// - returns: If the values are equal, `true`.

public func ==(lhs: Filters, rhs: Filters) -> Bool
{
    return lhs.category == rhs.category && lhs.gender == rhs.gender && lhs.price == rhs.price
}

extension Filters: Decoding, Encoding
{
    // MARK: - Coding

    /// Attempts to decode a `Filters` value from an encoded dictionary representation.
    ///
    /// - parameter encoded: An encoded dictionary representation.
    ///
    /// - throws: Errors encountered during decoding.
    public init(encoded: [String : Any]) throws
    {
        func decodeSet<Component: RawRepresentable>(_ input: [Component.RawValue]) throws -> Set<Component>
        {
            return try Set(input.map(decodeRaw))
        }

        self.init(
            price: try decodeSet(encoded.decode(Filters.priceKey)),
            gender: try decodeSet(encoded.decode(Filters.genderKey)),
            category: try decodeSet(encoded.decode(Filters.categoryKey))
        )
    }

    /// Encodes a `Filters` value to a dictionary representation.
    public var encoded: [String : Any]
    {
        return [
            Filters.priceKey: price.map({ $0.rawValue }),
            Filters.genderKey: gender.map({ $0.rawValue }),
            Filters.categoryKey: category.map({ $0.rawValue })
        ]
    }

    // MARK: - Coding Keys
    fileprivate static let priceKey = "price"
    fileprivate static let genderKey = "gender"
    fileprivate static let categoryKey = "category"
}

extension Filters: QueryItemsRepresentable
{
    // MARK: - Query Items

    /// The query items to use when applying the filters to a URL request.
    var queryItems: [URLQueryItem]
    {
        return Array([
            price.map({ price in
                URLQueryItem(name: "price_category_id", value: "\(price.rawValue)")
            }),
            gender.map({ gender in
                URLQueryItem(name: "gender", value: gender.rawValue)
            }),
            category.map({ category in
                URLQueryItem(name: "category", value: category.rawValue)
            })
        ].joined())
    }
}

// MARK: - Filter Components

/// A component of a `Filters` value. Implemented by `Category`, `Gender`, and `Price`.
public protocol FilterComponent: Hashable
{
    // MARK: - Properties

    /// The title of the category.
    static var title: String { get }

    /// All available items in the category.
    static var all: [Self] { get }
}

extension Sequence where Iterator.Element: FilterComponent
{
    /// Simplifies the set of components - if all components are in the set, it can be replaced with an
    /// empty set for the same effect.
    func simplifiedSet() -> Set<Iterator.Element>
    {
        let selfSet = Set(self)
        return selfSet == Set(Iterator.Element.all) ? [] : selfSet
    }
}

// MARK: - Prices

/// The price tiers that can be filtered on.
public enum Price: Int
{
    // MARK: - Items

    /// $1 to $25.
    case from1To25 = 1

    /// $25 to $50.
    case from25To50 = 2

    /// $50 to $100.
    case from50To100 = 3

    /// $100 to $500.
    case from100To500 = 4

    /// $500 to $1000.
    case from500To1000 = 5

    /// $1000 to $5000.
    case from1000To5000 = 6

    /// $5000 or more.
    case from5000Up = 7
}

extension Price: CustomStringConvertible
{
    // MARK: - Description
    public var description: String
    {
        switch self
        {
        case .from1To25:
            return "$1-25"
        case .from25To50:
            return "$25-50"
        case .from50To100:
            return "$50-100"
        case .from100To500:
            return "$100-500"
        case .from500To1000:
            return "$500-1000"
        case .from1000To5000:
            return "$1000-5000"
        case .from5000Up:
            return "$5000+"
        }
    }
}

extension Price: FilterComponent
{
    // MARK: - Filter Component

    /// The title of the price filter component.
    public static let title = "Price"

    /// All available price filters.
    public static var all: [Price]
    {
        return [.from1To25, .from25To50, .from50To100, .from100To500, .from500To1000, .from1000To5000, .from5000Up]
    }
}

// MARK: - Gender

/// The gender categories that can be filtered on.
public enum Gender: String
{
    // MARK: - Items

    /// Women's products.
    case female = "female"

    /// Men's products.
    case male = "male"

    /// Gender-neutral products (aren't they all?).
    case neutral = "neutral"
}

extension Gender: CustomStringConvertible
{
    // MARK: - Description
    public var description: String
    {
        switch self
        {
        case .female:
            return "Women's"
        case .male:
            return "Men's"
        case .neutral:
            return "Neutral"
        }
    }
}

extension Gender: FilterComponent
{
    // MARK: - Filter Component

    /// The title of the gender filter component.
    public static let title = "Gender"

    /// All available gender filters.
    public static var all: [Gender]
    {
        return [.female, .male, .neutral]
    }
}

// MARK: - Categories

/// The product categories that can be filtered on.
public enum Category: String
{
    // MARK: - Items

    /// Accessories.
    case Accessories = "accessories"

    /// Apparel.
    case Apparel = "apparel"

    /// Art.
    case Art = "art"

    /// Housegoods.
    case Home = "home"

    /// Media.
    case Media = "media"

    /// Shoes.
    case Shoes = "shoes"

    /// Tech.
    case Tech = "tech"

    /// Other.
    case Other = "other"
}

extension Category: FilterComponent
{
    // MARK: - Filter Component

    /// The title of the price filter component.
    public static let title = "Category"

    /// All available category filters.
    public static var all: [Category]
    {
        return [.Accessories, .Apparel, .Art, .Home, .Media, .Shoes, .Tech, .Other]
    }
}
