import Combine
import Dependencies
import Foundation

extension Publisher where Failure == Never {
    public func nextValue() async throws -> Output {
        var cancellable: AnyCancellable? = nil
        let continuationIsolated: LockIsolated<CheckedContinuation<Output, any Error>?> = .init(nil)

        let value = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                continuationIsolated.withValue { $0 = continuation }
                cancellable = self.sink { value in
                    continuation.resume(returning: value)
                }
            }
        } onCancel: {
            continuationIsolated.withValue { $0?.resume(throwing: CancellationError()) }
        }

        cancellable?.cancel()
        return value
    }
}
