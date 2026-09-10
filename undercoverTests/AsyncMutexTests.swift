//
//  AsyncMutexTests.swift
//  undercoverTests
//
//
//  AsyncMutexTests.swift
//  undercoverTests
//

import Testing
@testable import undercover

private actor CriticalSectionProbe {
    private var activeCount = 0
    private var maximumActiveCount = 0

    func enter() {
        activeCount += 1
        maximumActiveCount = max(maximumActiveCount, activeCount)
    }

    func leave() {
        activeCount -= 1
    }

    func maximumActive() -> Int {
        maximumActiveCount
    }
}

struct AsyncMutexTests {

    @Test
    func withLock_allowsOnlyOneTaskInTheCriticalSection() async {
        let mutex = AsyncMutex()
        let probe = CriticalSectionProbe()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    await mutex.withLock {
                        await probe.enter()

                        try? await Task.sleep(
                            nanoseconds: 10_000_000
                        )

                        await probe.leave()
                    }
                }
            }
        }

        let maximumActive = await probe.maximumActive()

        #expect(maximumActive == 1)
    }

    @Test
    func withLock_returnsTheOperationValue() async {
        let mutex = AsyncMutex()

        let value = await mutex.withLock {
            42
        }

        #expect(value == 42)
    }

    @Test
    func withLock_releasesTheLockAfterAnError() async {
        struct ExpectedError: Error {}

        let mutex = AsyncMutex()

        await #expect(throws: ExpectedError.self) {
            try await mutex.withLock {
                throw ExpectedError()
            }
        }

        let value = await mutex.withLock {
            "lock was released"
        }

        #expect(value == "lock was released")
    }
}
