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
import NSErrorRepresentable
import ReactiveCocoa
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

extension ProductRelationsEndpoint: EndpointType, MethodProviderType, URLProviderType
{
    // MARK: - Endpoint

    /// `GET` is used.
    var method: Endpoint.Method { return .Get }

    /// The Very Goods URL of the product.
    var URL: NSURL? { return NSURL(string: "https://verygoods.co/product/\(productIdentifier)") }
}

extension ProductRelationsEndpoint: ProcessingType
{
    func resultForInput(input: Message<NSHTTPURLResponse, NSData>) -> Result<ProductRelations, NSError>
    {
        let HTML = HTMLDocument(data: input.body, contentTypeHeader: nil)

        let headResult = Result(
            HTML.rootElement?.childElementNodes.lazy.filter({ $0.tagName.lowercaseString == "head" }).first,
            failWith: ProductRelationsError.FailedToFindHead.NSError
        )

        let encodedResult = headResult.flatMap({ head in
            head.JSONResultWith(identifier: "related_products")
                .flatMap({ any in
                    Result(
                        any as? [[String:AnyObject]],
                        failWith: ProductRelationsError.InvalidRelatedProductsJSONType.NSError
                    )
                })
                &&& head.JSONResultWith(identifier: "product")
                    .flatMap({ any in
                        Result(
                            ((any as? [String:AnyObject])?["_embedded"] as? [String:AnyObject]),
                            failWith: ProductRelationsError.InvalidProductJSONType.NSError
                        )
                    })
                    .flatMap({ dictionary in
                        Result(
                            (dictionary["in_user_goods"] as? [String:AnyObject])?["users"] as? [[String:AnyObject]] ?? [],
                            failWith: ProductRelationsError.CouldNotFindInUserGoods.NSError
                        )
                    })
        })

        return encodedResult.flatMap({ encodedRelated, encodedUsers in
            Result(attempt: {
                try rethrowNSError(
                    ProductRelations(
                        relatedProducts: try encodedRelated.map(Product.init),
                        users: try encodedUsers.map(User.init)
                    )
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
    private func JSONResultWith(identifier identifier: String) -> Result<AnyObject, NSError>
    {
        return Result(
            scriptWith(identifier: identifier),
            failWith: ProductRelationsError.FailedToFindScriptTag.NSError
        ).flatMap({ $0.JSONResult() })
    }

    /**
     Yields the script tag child of the element with the specified identifier (`id`), if any.

     - parameter identifier: The identifier to search for.
     */
    private func scriptWith(identifier identifier: String) -> HTMLElement?
    {
        return childElementNodes.lazy.filter({
            $0.tagName.lowercaseString == "script" && $0.attributes["id"] == identifier
        }).first
    }

    /// A result for reinterpreting the element's inner HTML as JSON data.
    private func JSONResult() -> Result<AnyObject, NSError>
    {
        let dataResult = Result(
            innerHTML.dataUsingEncoding(NSUTF8StringEncoding),
            failWith: ProductRelationsError.CouldNotEncodeInnerHTML.NSError
        )

        return dataResult.flatMap({ data in
            Result(attempt: { try NSJSONSerialization.JSONObjectWithData(data, options: []) })
        })
    }
}

// MARK: - Product Relations Errors

/// Enumerates errors that may arise while loading product relations.
public enum ProductRelationsError: Int, ErrorType
{
    // MARK: - Cases

    /// The `head` tag could not be found in the parsed HTML.
    case FailedToFindHead

    /// A script tag could not be found in the parsed HTML.
    case FailedToFindScriptTag

    /// The inner HTML of a tag could not be encoded as data.
    case CouldNotEncodeInnerHTML

    /// The related products JSON did not match the expected type.
    case InvalidRelatedProductsJSONType

    /// The product JSON did not match the expected type.
    case InvalidProductJSONType

    /// The `in_user_goods` key could not be found in the product JSON.
    case CouldNotFindInUserGoods
}

extension ProductRelationsError: NSErrorConvertible
{
    // MARK: - Error Convertible

    /// `PrettyOkayKit.ProductRelationsError`.
    public static var domain: String { return "PrettyOkayKit.ProductRelationsError" }
}
