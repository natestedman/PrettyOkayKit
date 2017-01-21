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

import ReactiveSwift
import enum Result.NoError

// MARK: - Client

/// Manages the wanting and unwanting of products.
public final class WantClient
{
    // MARK: - Initialization

    /// Initializes a want client.
    ///
    /// - parameter api: The API client to make requests with.
    /// - parameter log: A logging function for errors.
    public init(api: APIClient, log: @escaping (String) -> () = { _ in })
    {
        self.api = api
        self.log = log
    }

    // MARK: - Storage

    /// The API client backing the want client.
    fileprivate let api: APIClient

    /// A logging function.
    fileprivate let log: (String) -> ()

    /// The current states of the want client.
    fileprivate let states = MutableProperty<[ModelIdentifier:WantClientState]>([:])

    // MARK: - Change Notifications

    /// A backing pipe for `changedSignal`.
    fileprivate let changedPipe = Signal<(), NoError>.pipe()

    /// A signal that sends a value whenever a want is changed on the server.
    public var changedSignal: Signal<(), NoError> { return changedPipe.0 }
}

extension WantClient
{
    // MARK: - Initializing Want State

    /// Initializes the want state for the specified product identifier.
    ///
    /// - parameter identifier:     The product identifier to use.
    /// - parameter goodDeletePath: If the product is wanted, the path to delete its `Good`.
    public func initialize(identifier: Int, goodDeletePath: String?)
    {
        states.modify({ current in
            if let clientState = current[identifier], clientState.goodDeletePath != nil, goodDeletePath == nil
            {
                current.removeValue(forKey: identifier)
            }
            else if let path = goodDeletePath
            {
                current[identifier] = .wanted(goodDeletePath: path)
            }
        })
    }
}

extension WantClient
{
    // MARK: - Modifying Want State

    /// Modifies the want state of the specified product identifier.
    ///
    /// - parameter identifier: The product identifier.
    /// - parameter want:       The desired want state.
    public func modify(identifier: Int, want: Bool)
    {
        guard let username = api.authentication?.username else { return }
        let session = api.endpointSession

        // a producer to obtain the CSRF token for the request
        let csrfTokenProducer = api.csrfToken.producer
            .promoteErrors(NSError.self)
            .skipNil()
            .take(first: 1)
            .timeout(
                after: 10,
                raising: WantClientError.csrfTokenTimeout as NSError,
                on: QueueScheduler.main
            )

        // a producer to make the want or unwant request
        let requestProducer = csrfTokenProducer
            .zip(with: states.producer.promoteErrors(NSError.self))
            .take(first: 1)
            .flatMap(.concat, transform: { csrfToken, states in
                want
                    ? session.baseURLEndpointProducer(for: WantEndpoint(
                        username: username,
                        identifier: identifier,
                        csrfToken: csrfToken
                    ))
                    : (states[identifier]?.goodDeletePath).map({ goodDeletePath in
                        session.baseURLEndpointProducer(for: UnwantEndpoint(
                            goodDeletePath: goodDeletePath,
                            csrfToken: csrfToken
                        ))
                    }) ?? SignalProducer(error: WantClientError.missingGoodDeletePath as NSError)
            })
            .observe(on: QueueScheduler(qos: .userInitiated, name: "WantClient"))

        // a producer that handles terminating events
        let completionProducer = requestProducer.on(
            failed: { [weak self] error in
                self?.log("Error while modifying want state to \(want) for \(identifier): \(error)")
                self?.states.modify({ $0 [identifier] = nil }) // TODO: rollback unwant
            },
            value: { [weak self] path in
                self?.states.modify({ $0[identifier] = path.map(WantClientState.wanted) })
                self?.changedPipe.1.send(value: ())
            }
        )

        states.modify({ states in
            if let clientState = states[identifier]
            {
                switch clientState
                {
                case .wanted:
                    states[identifier] = .modifying(
                        disposable: completionProducer.start(),
                        want: want
                    )

                case let .modifying(disposable, modifyingWant):
                    if want != modifyingWant
                    {
                        disposable.dispose()

                        states[identifier] = .modifying(
                            disposable: completionProducer.start(),
                            want: want
                        )
                    }
                }
            }
            else
            {
                states[identifier] = .modifying(
                    disposable: completionProducer.start(),
                    want: want
                )
            }
        })
    }
}

extension WantClient
{
    // MARK: - Observing Want State

    /// A signal producer for a specific product's want state.
    ///
    /// - parameter identifier: The product identifier to observe.
    public func wantStateProducer(identifier: Int) -> SignalProducer<WantState, NoError>
    {
        return states.producer.map({ states in
            states[identifier].map({ clientState in
                switch clientState
                {
                case .wanted:
                    return .Wanted
                case let .modifying(_, want):
                    return want ? .modifyingToWanted : .modifyingToNotWanted
                }
            }) ?? .notWanted
        }).skipRepeats()
    }
}

// MARK: - Want Client Errors

/// Errors that may be raised by `WantClient`.
public enum WantClientError: Int, Error
{
    // MARK: - Cases

    /// A CSRF token could not be obtained for the request.
    case csrfTokenTimeout

    /// There was no delete path for the product.
    case missingGoodDeletePath
}

extension WantClientError: CustomNSError
{
    // MARK: - NSError

    /// `PrettyOkayKit.WantClientError`
    public static var errorDomain: String { return "PrettyOkayKit.WantClientError" }
}

/// Describes the state of an individual product, with respect to `WantClient`. A non-wanted state is omitted for
/// efficiency, as it can be inferred from the absense of a value.
private enum WantClientState
{
    // MARK: - Cases

    /// The user wants the product.
    case wanted(goodDeletePath: String)

    /// The want state is being modified.
    case modifying(disposable: Disposable, want: Bool)
}

extension WantClientState
{
    // MARK: - Good Deletion

    /// The good delete path, if the state is `.Wanted`.
    var goodDeletePath: String?
    {
        switch self
        {
        case let .wanted(goodDeletePath):
            return goodDeletePath

        case .modifying:
            return nil // TODO
        }
    }
}
