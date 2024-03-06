public func withTimeout<T: Sendable>(for duration: Duration, _ operation: @Sendable @escaping () async throws -> T) async rethrows -> T? {
    try await withThrowingTaskGroup(of: T?.self) { group in
        group.addTask {
            try? await Task.sleep(for: duration)
            return nil
        }
        
        group.addTask {
            try await operation()
        }
        
        for try await value in group {
            return value
        }
        return nil
    }
}
