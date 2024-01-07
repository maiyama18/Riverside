@testable import Models

import CustomDump
import SwiftData
import XCTest

final class StreamSectionBuilderTests: XCTestCase {
    private let modelContainer = try! ModelContainer(
        for: EntryModel.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    
    func test() {
        let entry1 = EntryModel(
            urlString: "https://example.com/1",
            publishedAtString: "2023-12-31T23:00:00+09:00",
            read: false
        )
        let entry2 = EntryModel(
            urlString: "https://example.com/2",
            publishedAtString: "2024-01-01T01:00:00+09:00",
            read: false
        )
        let entry3 = EntryModel(
            urlString: "https://example.com/3",
            publishedAtString: "2024-01-01T02:00:00+09:00",
            read: true
        )
        let entry4 = EntryModel(
            urlString: "https://example.com/4",
            publishedAtString: "2024-01-01T03:00:00+09:00",
            read: false
        )
        let entry5 = EntryModel(
            urlString: "https://example.com/5",
            publishedAtString: "2024-01-02T23:00:00+09:00",
            read: true
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
            StreamSectionBuilder.build(entries: entries, unreadOnly: false, calendar: calendar),
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
        
        XCTAssertNoDifference(
            StreamSectionBuilder.build(entries: entries, unreadOnly: true, calendar: calendar),
            [
                .init(
                    publishedDate: try! Date("2024-01-01T00:00:00+09:00", strategy: .iso8601),
                    entries: [entry4, entry2]
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
    convenience init(urlString: String, publishedAtString: String, read: Bool) {
        self.init(
            url: urlString,
            title: "Dummy Title",
            publishedAt: try! Date(publishedAtString, strategy: .iso8601),
            content: nil
        )
        self.read = read
    }
}
