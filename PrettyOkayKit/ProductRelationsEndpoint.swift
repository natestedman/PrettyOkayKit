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

import Endpoint
import Foundation
import HTMLReader
import ReactiveSwift
import Result
import Shirley

// MARK: - Endpoint

/// Retrieves relations for a product.
///
/// This data is not available via JSON API, so this endpoint uses an HTML parser to extract the data.
struct ProductRelationsEndpoint
{
    // MARK: - Identifier

    /// The identifier of the product to look up details for.
    let productIdentifier: ModelIdentifier
}

extension ProductRelationsEndpoint: Endpoint, HTTPMethodProvider, URLProvider
{
    // MARK: - Endpoint

    /// `GET` is used.
    var httpMethod: HTTPMethod { return .get }

    /// The Very Goods URL of the product.
    var url: URL? { return Foundation.URL(string: "https://verygoods.co/product/\(productIdentifier)") }
}

extension ProductRelationsEndpoint: ResultProcessing
{
    func result(for input: Message<HTTPURLResponse, Data>) -> Result<ProductRelations, NSError>
    {
        let HTML = HTMLDocument(data: input.body, contentTypeHeader: nil)

        let headResult = Result(
            HTML.rootElement?.childElementNodes.lazy.filter({ $0.tagName.lowercased() == "head" }).first,
            failWith: ProductRelationsError.failedToFindHead as NSError
        )

        let encodedResult = headResult.flatMap({ head in
            head.JSONResultWith(identifier: "related_products")
                .flatMap({ any in
                    Result(
                        any as? [[String:Any]],
                        failWith: ProductRelationsError.invalidRelatedProductsJSONType as NSError
                    )
                })
                &&& head.JSONResultWith(identifier: "product")
                    .flatMap({ any in
                        Result(
                            ((any as? [String:Any])?["_embedded"] as? [String:Any]),
                            failWith: ProductRelationsError.invalidProductJSONType as NSError
                        )
                    })
                    .flatMap({ dictionary in
                        Result(
                            (dictionary["in_user_goods"] as? [String:Any])?["users"] as? [[String:Any]] ?? [],
                            failWith: ProductRelationsError.couldNotFindInUserGoods as NSError
                        )
                    })
        })

        return encodedResult.flatMap({ encodedRelated, encodedUsers in
            Result(attempt: {
                ProductRelations(
                    relatedProducts: try encodedRelated.map(Product.init),
                    users: try encodedUsers.map(User.init)
                )
            })
        })
    }
}

extension HTMLElement
{
    /**
     Yields the JSON value of the script tag child of the element with the specified identifier (`id`), if any.

     - parameter identifier: The identifier to search for
     */
    fileprivate func JSONResultWith(identifier: String) -> Result<Any, NSError>
    {
        return Result(
            scriptWith(identifier: identifier),
            failWith: ProductRelationsError.failedToFindScriptTag as NSError
        ).flatMap({ $0.JSONResult() })
    }

    /**
     Yields the script tag child of the element with the specified identifier (`id`), if any.

     - parameter identifier: The identifier to search for.
     */
    fileprivate func scriptWith(identifier: String) -> HTMLElement?
    {
        return childElementNodes.lazy.filter({
            $0.tagName.lowercased() == "script" && $0.attributes["id"] == identifier
        }).first
    }

    /// A result for reinterpreting the element's inner HTML as JSON data.
    fileprivate func JSONResult() -> Result<Any, NSError>
    {
        let dataResult = Result(
            innerHTML.data(using: .utf8),
            failWith: ProductRelationsError.couldNotEncodeInnerHTML as NSError
        )

        return dataResult.flatMap({ data in
            Result(attempt: { try JSONSerialization.jsonObject(with: data, options: []) })
        })
    }
}

// MARK: - Product Relations Errors

/// Enumerates errors that may arise while loading product relations.
public enum ProductRelationsError: Int, Error
{
    // MARK: - Cases

    /// The `head` tag could not be found in the parsed HTML.
    case failedToFindHead

    /// A script tag could not be found in the parsed HTML.
    case failedToFindScriptTag

    /// The inner HTML of a tag could not be encoded as data.
    case couldNotEncodeInnerHTML

    /// The related products JSON did not match the expected type.
    case invalidRelatedProductsJSONType

    /// The product JSON did not match the expected type.
    case invalidProductJSONType

    /// The `in_user_goods` key could not be found in the product JSON.
    case couldNotFindInUserGoods
}

extension ProductRelationsError: LocalizedError
{
    // MARK: - Error Convertible

    /// `PrettyOkayKit.ProductRelationsError`.
    public static var errorDomain: String { return "PrettyOkayKit.ProductRelationsError" }
}
