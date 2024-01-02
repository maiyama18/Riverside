import Algorithms
import Foundation
import Models

struct StreamSection {
    let publishedDate: Date
    let entries: [EntryModel]
}

enum StreamSectionBuilder {
    static func build(entries: [EntryModel], unreadOnly: Bool) -> [StreamSection] {
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local
        
        let sections: [StreamSection] = Dictionary(grouping: entries.uniqued(on: \.url).filter({ unreadOnly ? $0.read == false : true })) { entry -> Date in
            calendar.startOfDay(for: entry.publishedAt)
        }.map { (publishedDate, entries) -> StreamSection in
            StreamSection(publishedDate: publishedDate, entries: entries)
        }
        
        return sections.sorted(by: { $0.publishedDate > $1.publishedDate })
    }
}
