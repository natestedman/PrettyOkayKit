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

final class UserTests: XCTestCase
{
    func testDecodeNullOptionals()
    {
        let encoded: [String:AnyObject] = [
            "_links":[
                "password_reset":[
                    "href":"/account/password-reset?user_id=1"
                ],
                "self":[
                    "href":"/users/1"
                ]
            ],
            "avatar_image_key": NSNull(),
            "avatar_url": NSNull(),
            "avatar_url_centered_126": NSNull(),
            "bio": NSNull(),
            "cover_image": NSNull(),
            "cover_image_big_url": NSNull(),
            "cover_image_key": NSNull(),
            "cover_image_thumb_url": NSNull(),
            "created_at": [
                "_date":"2014-08-14T20:55:51.201380+00:00"
            ],
            "good_count": 100,
            "id": 1,
            "last_activity_at": [
                "_date":"2014-08-14T20:55:51.848298+00:00"
            ],
            "location": NSNull(),
            "name": "Test",
            "updated_at": [
                "_date":"2014-08-14T20:55:51.848256+00:00"
            ],
            "url": NSNull(),
            "username":"test"
        ]

        XCTAssertEqual(try? User(encoded: encoded), User(
            identifier: 1,
            username: "test", name: "Test",
            biography: nil,
            location: nil,
            URL: nil,
            avatarURL: nil,
            avatarURLCentered126: nil,
            coverURL: nil,
            coverLargeURL: nil,
            coverThumbURL: nil,
            goodsCount: 100
        ))
    }

    func testDecodeNonNullOptionals()
    {
        let encoded: [String:AnyObject] = [
            "_links":[
                "password_reset":[
                    "href":"/account/password-reset?user_id=1"
                ],
                "self":[
                    "href":"/users/1"
                ]
            ],
            "avatar_image_key": NSNull(),
            "avatar_url": "http://test.com/avatar",
            "avatar_url_centered_126": "http://test.com/avatar_126",
            "bio": "Test Bio",
            "cover_image": "http://test.com/cover",
            "cover_image_big_url": "http://test.com/cover_big",
            "cover_image_key": NSNull(),
            "cover_image_thumb_url": "http://test.com/cover_thumb",
            "created_at": [
                "_date":"2014-08-14T20:55:51.201380+00:00"
            ],
            "good_count": 100,
            "id": 1,
            "last_activity_at": [
                "_date":"2014-08-14T20:55:51.848298+00:00"
            ],
            "location": "Test Location",
            "name": "Test",
            "updated_at": [
                "_date":"2014-08-14T20:55:51.848256+00:00"
            ],
            "url": "http://test.com",
            "username":"test"
        ]

        XCTAssertEqual(try? User(encoded: encoded), User(
            identifier: 1,
            username: "test", name: "Test",
            biography: "Test Bio",
            location: "Test Location",
            URL: NSURL(string: "http://test.com")!,
            avatarURL: NSURL(string: "http://test.com/avatar")!,
            avatarURLCentered126: NSURL(string: "http://test.com/avatar_126")!,
            coverURL: NSURL(string: "http://test.com/cover")!,
            coverLargeURL: NSURL(string: "http://test.com/cover_big")!,
            coverThumbURL: NSURL(string: "http://test.com/cover_thumb")!,
            goodsCount: 100
        ))
    }
}
