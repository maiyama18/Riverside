import Dependencies
import OSLog

extension Logger: @unchecked Sendable {}

extension Logger {
    static func subsystem() -> String {
        Bundle.main.bundleIdentifier ?? "com.muijp.Riverside"
    }

    public subscript(category: LogCategory) -> Logger {
        return Logger(
            subsystem: Self.subsystem(),
            category: category.rawValue
        )
    }
}

extension Logger: DependencyKey {
    public static var liveValue: Logger { Logger() }
    public static var testValue: Logger { Logger() }
    public static var previewValue: Logger { Logger() }
}

extension DependencyValues {
    public var logger: Logger {
        get { self[Logger.self] }
        set { self[Logger.self] = newValue }
    }
}
