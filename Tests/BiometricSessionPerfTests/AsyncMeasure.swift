//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import XCTest

extension XCTestCase {
    /// Runs async work inside `measure`. The test thread blocks on a semaphore
    /// while a detached task does the work, so the actor is never starved.
    /// The semaphore adds a fixed overhead. Compare runs on the same machine only.
    func measureAsync(
        _ work: @escaping @Sendable () async -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        measure {
            let done = DispatchSemaphore(value: 0)
            Task.detached {
                await work()
                done.signal()
            }
            done.wait()
        }
    }
}
