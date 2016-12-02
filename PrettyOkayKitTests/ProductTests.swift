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

@testable import PrettyOkayKit
import XCTest

final class ProductTests: XCTestCase
{
    private func encoded(links links: [String:AnyObject]) -> [String:AnyObject]
    {
        return [
            "_links": links,
            "categories": [
                [
                    "id": 1,
                    "name": "Apparel",
                    "slug": "apparel"
                ]
            ],
            "created_at": [
                "_date": "2016-11-28T18:51:52.300163+00:00"
            ],
            "currency":  NSNull(),
            "domain_for_display": "test.com",
            "formatted_price": "$25-$50",
            "gender": "male",
            "id": 1,
            "image_bucket":  NSNull(),
            "image_key": "1234",
            "image_url": "https://test.com/image",
            "in_your_goods": false,
            "medium_image_url": "https://test.com/image_medium",
            "orig_image_url": "https://test.com/image_orig",
            "price_category": [
                "id": 2,
                "range_max": 50,
                "range_min": 25
            ],
            "price_category_id": 2,
            "slug": "test",
            "source_domain": "https://test.com",
            "source_url": "https://test.com/product",
            "title": "Test",
            "updated_at": [
                "_date": "2016-11-28T18:51:59.371457+00:00"
            ]
        ]
    }

    private let linksNoDelete: [String:AnyObject] = [
        "good:add": [
            "href": "/users/test/goods"
        ],
        "self": [
            "href": "/products/1"
        ]
    ]

    private let linksWithDelete: [String:AnyObject] = [
        "good:delete": [
            "href": "/test/path"
        ],
        "self": [
            "href": "/products/1"
        ]
    ]

    func testDecodeNoDeleteNoCustomLinks()
    {
        let encoded = self.encoded(links: linksNoDelete)

        XCTAssertEqual(try? Product.decode(encoded), Product(
            identifier: 1,
            title: "Test",
            formattedPrice: "$25-$50",
            gender: .Male,
            imageURL: NSURL(string: "https://test.com/image"),
            mediumImageURL: NSURL(string: "https://test.com/image_medium"),
            originalImageURL: NSURL(string: "https://test.com/image_orig"),
            displayDomain: "test.com",
            sourceDomain: NSURL(string: "https://test.com"),
            sourceURL: NSURL(string: "https://test.com/product"),
            goodDeletePath: nil
        ))
    }

    func testDecodeWithDeleteNoCustomLinks()
    {
        let encoded = self.encoded(links: linksWithDelete)

        XCTAssertEqual(try? Product.decode(encoded), Product(
            identifier: 1,
            title: "Test",
            formattedPrice: "$25-$50",
            gender: .Male,
            imageURL: NSURL(string: "https://test.com/image"),
            mediumImageURL: NSURL(string: "https://test.com/image_medium"),
            originalImageURL: NSURL(string: "https://test.com/image_orig"),
            displayDomain: "test.com",
            sourceDomain: NSURL(string: "https://test.com"),
            sourceURL: NSURL(string: "https://test.com/product"),
            goodDeletePath: "test/path"
        ))
    }

    func testDecodeNoDeleteWithCustomLinksNoDelete()
    {
        let encoded = self.encoded(links: linksNoDelete)

        XCTAssertEqual(try? Product.decode(encoded, links: linksNoDelete), Product(
            identifier: 1,
            title: "Test",
            formattedPrice: "$25-$50",
            gender: .Male,
            imageURL: NSURL(string: "https://test.com/image"),
            mediumImageURL: NSURL(string: "https://test.com/image_medium"),
            originalImageURL: NSURL(string: "https://test.com/image_orig"),
            displayDomain: "test.com",
            sourceDomain: NSURL(string: "https://test.com"),
            sourceURL: NSURL(string: "https://test.com/product"),
            goodDeletePath: nil
        ))
    }

    func testDecodeNoDeleteWithCustomLinksWithDelete()
    {
        let encoded = self.encoded(links: linksNoDelete)

        XCTAssertEqual(try? Product.decode(encoded, links: linksWithDelete), Product(
            identifier: 1,
            title: "Test",
            formattedPrice: "$25-$50",
            gender: .Male,
            imageURL: NSURL(string: "https://test.com/image"),
            mediumImageURL: NSURL(string: "https://test.com/image_medium"),
            originalImageURL: NSURL(string: "https://test.com/image_orig"),
            displayDomain: "test.com",
            sourceDomain: NSURL(string: "https://test.com"),
            sourceURL: NSURL(string: "https://test.com/product"),
            goodDeletePath: "test/path"
        ))
    }
}
