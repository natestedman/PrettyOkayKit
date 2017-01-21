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

// MARK: - State

/// Describes the want state of a product (see `WantClient` for usage).
public enum WantState
{
    // MARK: - Cases

    /// The user does not want the product.
    case notWanted

    /// The user wants the product.
    case wanted

    /// The client is modifying the product's want state to `NotWanted`.
    case modifyingToNotWanted

    /// The client is modifying the product's want state to `Wanted`.
    case modifyingToWanted
}

extension WantState
{
    // MARK: - Want State

    /// `true` if the value is `wanted` or `modifyingToWanted`.
    public var isWanted: Bool
    {
        switch self
        {
        case .wanted, .modifyingToWanted:
            return true
        case .notWanted, .modifyingToNotWanted:
            return false
        }
    }

    /// `true` if the value `modifyingToNotWanted` or `modifyingToWanted`.
    public var isModifying: Bool
    {
        switch self
        {
        case .modifyingToWanted, .modifyingToNotWanted:
            return true
        case .wanted, .notWanted:
            return false
        }
    }
}
