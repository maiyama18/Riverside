import Combine
import Foundation

extension Publisher where Failure == Never {
    public func nextValue() async -> Output {
        var cancellable: AnyCancellable?
        let value = await withCheckedContinuation { continuation in
            cancellable = self.sink { value in
                continuation.resume(returning: value)
            }
        }
        _ = cancellable
        return value
    }
}
