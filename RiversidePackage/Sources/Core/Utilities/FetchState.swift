public enum FetchState<T: Sendable>: Sendable {
    case fetching
    case fetched(T)
    case failed(Error)
}
