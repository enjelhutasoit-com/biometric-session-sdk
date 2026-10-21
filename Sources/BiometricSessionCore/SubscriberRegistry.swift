//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Holds the stream continuations of one `SessionController`.
///
/// Internal. Only the controller touches it, always from its own isolation.
/// When the controller is released, this object is released, and every
/// stream finishes. That is the only reason this is a class.
final class SubscriberRegistry {
    private var continuations: [Int: AsyncStream<SessionState>.Continuation] = [:]
    private var nextID = 0

    var count: Int { continuations.count }

    func add(_ continuation: AsyncStream<SessionState>.Continuation) -> Int {
        let id = nextID
        nextID += 1
        continuations[id] = continuation
        return id
    }

    func remove(_ id: Int) {
        continuations[id] = nil
    }

    func publish(_ state: SessionState) {
        for continuation in continuations.values {
            continuation.yield(state)
        }
    }

    deinit {
        for continuation in continuations.values {
            continuation.finish()
        }
    }
}
