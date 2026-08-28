//
//  AsyncMutex.swift
//  undercover
//
//  Created by Iheb on 27/08/2026.
//

import Foundation

actor AsyncMutex {
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func lock() async {
        if !isLocked {
            isLocked = true
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func unlock() {
        if waiters.isEmpty {
            isLocked = false
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }

    func withLock<T>(
        _ operation: () async throws -> T
    ) async rethrows -> T {
        await lock()

        defer {
            unlock()
        }

        return try await operation()
    }
}
