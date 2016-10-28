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

import ArrayLoader
import Foundation
import Result

// MARK: - Index Pages
struct IndexPage
{
    let index: Int
}

extension IndexPage: QueryItemsRepresentable
{
    var queryItems: [NSURLQueryItem]
    {
        return [NSURLQueryItem(name: "page", value: String(index))]
    }
}

// MARK: - Model Pages

/// A page determined by placement before or after a model.
enum ModelPage
{
    // MARK: - Pages

    /// The first page.
    case First

    /// The page after a model.
    case After(ModelType)

    /// The page before a model.
    case Before(ModelType)
}

extension ModelPage
{
    // MARK: - Load Requests

    /**
     Creates a `ModelPage` from a `LoadRequest`, if possible.

     - parameter request: The load request.
     */
    static func pageForLoadRequest<Model: ModelType>(request: LoadRequest<Model>) -> Result<ModelPage, NSError>
    {
        switch request
        {
        case .Next(let current):
            if let last = current.last
            {
                return .Success(.After(last))
            }
            else
            {
                return .Success(.First)
            }
        case .Previous(let current):
            if let first = current.first
            {
                return .Success(.Before(first))
            }
            else
            {
                return .Failure(APIClientLoadingError.FirstPageNotLoaded.NSError)
            }
        }
    }
}

extension ModelPage: QueryItemsRepresentable
{
    // MARK: - Query Items

    /// The query items required to load the page.
    var queryItems: [NSURLQueryItem]
    {
        switch self
        {
        case .First:
            return []
        case .After(let model):
            return [NSURLQueryItem(name: "max_id", value: "\(model.identifier)")]
        case .Before(let model):
            return [NSURLQueryItem(name: "since_id", value: "\(model.identifier)")]
        }
    }
}

// MARK: - Offset Pages
struct OffsetPage
{
    /// The number of items to skip.
    let skip: Int
}

extension OffsetPage: QueryItemsRepresentable
{
    var queryItems: [NSURLQueryItem]
    {
        return [NSURLQueryItem(name: "skip", value: "\(skip)")]
    }
}

// MARK: - Ordering

/// The orders that items can be loaded in.
public enum Order: String
{
    /// Alphabetical order.
    case Alphabetical = "alphabetical"

    /// Newest items first.
    case Newest = "newest"
}

extension Order: QueryItemsRepresentable
{
    var queryItems: [NSURLQueryItem]
    {
        return [NSURLQueryItem(name: "order", value: rawValue)]
    }
}
