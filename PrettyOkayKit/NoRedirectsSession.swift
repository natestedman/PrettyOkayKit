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
import ReactiveCocoa
import Shirley

/// A session that will not follow redirects.
internal final class NoRedirectsSession
{
    // MARK: - Initialization
    init(configuration: NSURLSessionConfiguration)
    {
        let delegate = NoRedirectsURLSessionDelegate()
        self.delegate = delegate
        self.session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    // MARK: - Session and Delegate
    private let session: NSURLSession
    private let delegate: NoRedirectsURLSessionDelegate
}

extension NoRedirectsSession: SessionType
{
    // MARK: - Session Type
    func producerForRequest(request: NSURLRequest) -> SignalProducer<Message<NSURLResponse, NSData>, NSError>
    {
        return session.producerForRequest(request)
    }
}

// MARK: - Session Delegate
private final class NoRedirectsURLSessionDelegate: NSObject, NSURLSessionDelegate
{
    @objc func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        willPerformHTTPRedirection response: NSHTTPURLResponse,
        newRequest request: NSURLRequest,
        completionHandler: (NSURLRequest?) -> Void)
    {
        // do not follow redirects, we need the cookie values for authentication
        completionHandler(nil)
    }
}
