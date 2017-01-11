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

/// A protocol for decoding model values from dictionary representations.
public protocol Decoding
{
    /// Initializes a value from a dictionary representation.
    ///
    /// - Parameter encoded: The dictionary representation.
    /// - Throws: An error encountered while decoding.
    init(encoded: [String:Any]) throws
}

extension Decoding
{
    /// Initializes a value by converting an `Any?` to a dictionary representation, then decoding.
    ///
    /// - Parameter anyEncoded: The `Any?` value.
    /// - Throws: `DecodeKeyError` with key `Any`, or an error encountered while decoding.
    public init(anyEncoded: Any?) throws
    {
        if let encoded = anyEncoded as? [String:Any]
        {
            try self.init(encoded: encoded)
        }
        else
        {
            throw DecodeKeyError(key: "Any")
        }
    }
}

/// A protocol for encoding model values as dictionary representations.
public protocol Encoding
{
    /// A dictionary representation of the value.
    var encoded: [String:Any] { get }
}
