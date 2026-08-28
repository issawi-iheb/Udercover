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

    // MARK: - Lock

    func lock() async {

        if !isLocked {
            isLocked = true
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    // MARK: - Unlock

    func unlock() {

        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            isLocked = false
        }
    }

    // MARK: - With Lock

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
