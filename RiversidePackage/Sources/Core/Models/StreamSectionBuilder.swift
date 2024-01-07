import Algorithms
import Foundation

public struct StreamSection: Equatable {
    public let publishedDate: Date
    public let entries: [EntryModel]
}

public enum StreamSectionBuilder {
    public static let defaultCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        return calendar
    }()
    
    public static func build(
        entries: [EntryModel],
        calendar: Calendar = defaultCalendar
    ) -> [StreamSection] {
        let sections: [StreamSection] = Dictionary(grouping: entries.uniqued(on: \.url)) { entry -> Date in
            calendar.startOfDay(for: entry.publishedAt)
        }.map { (publishedDate, entries) -> StreamSection in
            StreamSection(
                publishedDate: publishedDate,
                entries: entries.sorted(by: { $0.publishedAt > $1.publishedAt })
            )
        }
        
        return sections.sorted(by: { $0.publishedDate > $1.publishedDate })
    }
}
