@testable import Entities

import CustomDump
import CoreData
import XCTest

final class StreamSectionBuilderTests: XCTestCase {
    private let persistentProvider = PersistentProvider.inMemory
    private var context: NSManagedObjectContext { persistentProvider.viewContext }
    
    func test() {
        let entry1 = EntryModel(
            context,
            urlString: "https://example.com/1",
            publishedAtString: "2023-12-31T23:00:00+09:00"
        )
        let entry2 = EntryModel(
            context,
            urlString: "https://example.com/2",
            publishedAtString: "2024-01-01T01:00:00+09:00"
        )
        let entry3 = EntryModel(
            context,
            urlString: "https://example.com/3",
            publishedAtString: "2024-01-01T02:00:00+09:00"
        )
        let entry4 = EntryModel(
            context,
            urlString: "https://example.com/4",
            publishedAtString: "2024-01-01T03:00:00+09:00"
        )
        let entry5 = EntryModel(
            context,
            urlString: "https://example.com/5",
            publishedAtString: "2024-01-02T23:00:00+09:00"
        )
        
        let entries: [EntryModel] = [
            entry4,
            entry2,
            entry5,
            entry1,
            entry3,
        ]
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        
        XCTAssertNoDifference(
            StreamSectionBuilder.build(entries: entries, calendar: calendar),
            [
                .init(
                    publishedDate: try! Date("2024-01-02T00:00:00+09:00", strategy: .iso8601),
                    entries: [entry5]
                ),
                .init(
                    publishedDate: try! Date("2024-01-01T00:00:00+09:00", strategy: .iso8601),
                    entries: [entry4, entry3, entry2]
                ),
                .init(
                    publishedDate: try! Date("2023-12-31T00:00:00+09:00", strategy: .iso8601),
                    entries: [entry1]
                ),
            ]
        )
    }
}

private extension EntryModel {
    convenience init(_ context: NSManagedObjectContext, urlString: String, publishedAtString: String) {
        self.init(context: context)
        
        self.url = URL(string: urlString)
        self.publishedAt = try! Date(publishedAtString, strategy: .iso8601)
    }
}
