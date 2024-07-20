import XCTest

extension XCTestCase {
    public func waitUntilConditionSatisfied(timeout: Duration = .seconds(1), condition: @Sendable @escaping () async throws -> Bool) async throws {
        struct TimeoutError: Error {}

        try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await Task.sleep(for: timeout)
                return false
            }
            group.addTask {
                while try await !condition(), !Task.isCancelled {
                    for _ in 0..<10 {
                        await Task.yield()
                    }
                }
                return true
            }

            let conditionSatisfied = try await group.next()!
            group.cancelAll()
            if !conditionSatisfied {
                throw TimeoutError()
            }
        }
    }
}
