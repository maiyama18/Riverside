import Dependencies

public struct TimeoutError: Error {}

public func withRetry<T: Sendable>(count: Int, operation: @Sendable @escaping () async throws -> T) async rethrows -> T {
    for _ in 0..<(count-1) {
        do {
            return try await operation()
        } catch {}
    }
    return try await operation()
}

public func withTimeout<T: Sendable>(for duration: Duration, _ operation: @Sendable @escaping () async throws -> T) async rethrows -> T {
    @Dependency(\.continuousClock) var clock
    
    return try await withThrowingTaskGroup(of: T?.self) { group in
        group.addTask {
            try? await clock.sleep(for: duration)
            return nil
        }
        
        group.addTask {
            try await operation()
        }
        
        let value = try await group.next()!
        group.cancelAll()
        if let value {
            return value
        } else {
            throw TimeoutError()
        }
    }
}
