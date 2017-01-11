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


// MARK: - Decoding Errors

/// An error raised when a key is missing while decoding a model.
public struct DecodeKeyError: Error
{
    // MARK: - Key

    /// The missing key.
    public let key: String
}

extension DecodeKeyError: CustomNSError
{
    // MARK: - Error

    /// The error domain.
    public static var errorDomain: String { return "PrettyOkayKit.DecodeKeyError" }

    /// The error code, which is always `0`.
    public var errorCode: Int { return 0 }
}

extension DecodeKeyError: LocalizedError
{
    // MARK: - User Info

    /// A description of the error.
    public var errorDescription: String?
    {
        return "Could not decode key “\(key)”"
    }
}

/// An error raised when a key is missing while decoding a model.
public struct DecodeRawError<Raw>: Error
{
    // MARK: - Raw Value

    /// The invalid raw value.
    public let raw: Raw
}

extension DecodeRawError: CustomNSError
{
    // MARK: - Error

    /// The error domain.
    public static var errorDomain: String { return "PrettyOkayKit.DecodeRawError" }

    /// The error code, which is always `0`.
    public var errorCode: Int { return 0 }
}

extension DecodeRawError: LocalizedError
{
    // MARK: - User Info

    /// A description of the error.
    public var errorDescription: String?
    {
        return "Could not decode raw value “\(raw)”"
    }
}

/// An error raised when a decoded URL string is invalid.
public struct InvalidURLError: Error
{
    // MARK: - Properties

    /// The invalid URL string.
    public let URLString: String

    /// The key that the invalid URL string was retrieved from.
    public let key: String
}

extension InvalidURLError: CustomNSError
{
    // MARK: - Error

    /// The error domain.
    public static var errorDomain: String { return "PrettyOkayKit.InvalidURLError" }

    /// The error code, which is always `0`.
    public var errorCode: Int { return 0 }
}

extension InvalidURLError: LocalizedError
{
    // MARK: - User Info

    /// A description of the error.
    public var errorDescription: String?
    {
        return "Could not decode URL string “\(URLString)” for key “\(key)”"
    }
}
