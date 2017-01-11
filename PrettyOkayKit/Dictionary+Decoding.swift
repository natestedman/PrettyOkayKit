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

extension Dictionary
{
    func decode<Decoded>(_ key: Key) throws -> Decoded
    {
        if let value = self[key] as? Decoded
        {
            return value
        }
        else
        {
            throw DecodeKeyError(key: "\(key)")
        }
    }

    func decodeURL(_ key: Key) throws -> URL
    {
        let URLString: String = try decode(key)

        if let URL = URL(string: URLString), URL.scheme == "http" || URL.scheme == "https"
        {
            return URL
        }
        else
        {
            throw InvalidURLError(URLString: URLString, key: "\(key)")
        }
    }

    func sub(_ key: Key) throws -> Dictionary
    {
        return try decode(key)
    }
}
