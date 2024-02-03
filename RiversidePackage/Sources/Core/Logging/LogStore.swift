import Foundation
import OSLog

public struct LogEntry: Sendable {
    public var date: Date
    public var category: LogCategory
    public var level: OSLogEntryLog.Level
    public var message: String
}

public actor LogStore {
    public init() {}

    public func getAllLogEntries() throws -> [LogEntry] {
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(timeIntervalSinceLatestBoot: 1)

        return try store.getEntries(at: position)
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == Logger.subsystem() }
            .compactMap {
                guard let category = LogCategory(rawValue: $0.category) else { return nil }
                return LogEntry(
                    date: $0.date,
                    category: category,
                    level: $0.level,
                    message: $0.composedMessage
                )
            }
            .sorted(by: { $0.date > $1.date })
    }
}
