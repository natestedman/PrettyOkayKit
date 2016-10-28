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

import NSErrorRepresentable
import ReactiveCocoa
import enum Result.NoError

// MARK: - Client

/// Manages the wanting and unwanting of products.
public final class WantClient
{
    // MARK: - Initialization

    /// Initializes a want client.
    ///
    /// - parameter API: The API client to make requests with.
    public init(API: APIClient)
    {
        self.API = API
    }

    // MARK: - Storage

    /// The API client backing the want client.
    private let API: APIClient

    /// The current states of the want client.
    private let states = MutableProperty<[ModelIdentifier:WantClientState]>([:])

    // MARK: - Change Notifications

    /// A backing pipe for `changedSignal`.
    private let changedPipe = Signal<(), NoError>.pipe()

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
    public func initialize(identifier identifier: Int, goodDeletePath: String?)
    {
        states.modify({ current in
            if let clientState = current[identifier]
            {
                switch clientState
                {
                case .Wanted:
                    return goodDeletePath == nil
                        ? with(current) { $0.removeValueForKey(identifier) }
                        : current

                case .Modifying:
                    return current
                }
            }
            else if let path = goodDeletePath
            {
                return with(current) { $0[identifier] = .Wanted(goodDeletePath: path) }
            }
            else
            {
                return current
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
    public func modify(identifier identifier: Int, want: Bool)
    {
        guard let username = API.authentication?.username else { return }
        let session = API.endpointSession

        // a producer to obtain the CSRF token for the request
        let CSRFTokenProducer = API.CSRFToken.producer
            .promoteErrors(NSError.self)
            .ignoreNil()
            .take(1)
            .timeoutWithError(
                WantClientError.CSRFTokenTimeout.NSError,
                afterInterval: 10,
                onScheduler: QueueScheduler.mainQueueScheduler
            )

        // a producer to make the want or unwant request
        let requestProducer = CSRFTokenProducer
            .zipWith(states.producer.promoteErrors(NSError.self))
            .take(1)
            .flatMap(.Concat, transform: { CSRFToken, states in
                want
                    ? session.producerForEndpoint(WantEndpoint(
                        username: username,
                        identifier: identifier,
                        CSRFToken: CSRFToken
                    ))
                    : (states[identifier]?.goodDeletePath).map({ goodDeletePath in
                        session.producerForEndpoint(UnwantEndpoint(
                            goodDeletePath: goodDeletePath,
                            CSRFToken: CSRFToken
                        ))
                    }) ?? SignalProducer(error: WantClientError.MissingGoodDeletePath.NSError)
            })
            .observeOn(QueueScheduler(qos: QOS_CLASS_USER_INITIATED, name: "WantClient"))

        // a producer that handles terminating events
        let completionProducer = requestProducer.on(
            next: { [weak self] path in
                self?.states.modify({ states in
                    with(states) { $0[identifier] = path.map(WantClientState.Wanted) }
                })

                self?.changedPipe.1.sendNext()
            },
            failed: { [weak self] error in
                print("Error while modifying want state to \(want) for \(identifier): \(error)")

                self?.states.modify({ states in
                    with(states) { $0[identifier] = nil } // TODO: rollback unwant
                })
            }
        )

        states.modify({ states in
            if let clientState = states[identifier]
            {
                switch clientState
                {
                case .Wanted:
                    return with(states) {
                        $0[identifier] = .Modifying(
                            disposable: completionProducer.start(),
                            want: want
                        )
                    }

                case let .Modifying(disposable, modifyingWant):
                    if want == modifyingWant
                    {
                        return states
                    }
                    else
                    {
                        disposable.dispose()

                        return with(states) {
                            $0[identifier] = .Modifying(
                                disposable: completionProducer.start(),
                                want: want
                            )
                        }
                    }
                }
            }
            else
            {
                return with(states) {
                    $0[identifier] = .Modifying(
                        disposable: completionProducer.start(),
                        want: want
                    )
                }
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
    @warn_unused_result
    public func wantStateProducer(identifier identifier: Int) -> SignalProducer<WantState, NoError>
    {
        return states.producer.map({ states in
            states[identifier].map({ clientState in
                switch clientState
                {
                case .Wanted:
                    return .Wanted
                case let .Modifying(_, want):
                    return want ? .ModifyingToWanted : .ModifyingToNotWanted
                }
            }) ?? .NotWanted
        }).skipRepeats()
    }
}

// MARK: - Want Client Errors

/// Errors that may be raised by `WantClient`.
public enum WantClientError: Int, ErrorType
{
    // MARK: - Cases

    /// A CSRF token could not be obtained for the request.
    case CSRFTokenTimeout

    /// There was no delete path for the product.
    case MissingGoodDeletePath
}

extension WantClientError: NSErrorConvertible
{
    // MARK: - NSError

    /// `PrettyOkayKit.WantClientError`
    public static var domain: String { return "PrettyOkayKit.WantClientError" }
}

/// Describes the state of an individual product, with respect to `WantClient`. A non-wanted state is omitted for
/// efficiency, as it can be inferred from the absense of a value.
private enum WantClientState
{
    // MARK: - Cases

    /// The user wants the product.
    case Wanted(goodDeletePath: String)

    /// The want state is being modified.
    case Modifying(disposable: Disposable, want: Bool)
}

extension WantClientState
{
    // MARK: - Good Deletion

    /// The good delete path, if the state is `.Wanted`.
    var goodDeletePath: String?
    {
        switch self
        {
        case let .Wanted(goodDeletePath):
            return goodDeletePath

        case .Modifying:
            return nil // TODO
        }
    }
}

internal func with<Value>(value: Value, _ transform: (inout Value) -> ()) -> Value
{
    var mutable = value
    transform(&mutable)
    return mutable
}
