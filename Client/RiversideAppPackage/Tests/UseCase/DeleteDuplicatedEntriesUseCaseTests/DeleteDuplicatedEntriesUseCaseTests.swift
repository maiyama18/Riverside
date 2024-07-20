@testable import DeleteDuplicatedEntriesUseCase

import CustomDump
import CoreData
import Entities
import XCTest

@MainActor
final class DeleteDuplicatedEntriesUseCaseTests: XCTestCase {
    private let persistentProvider = PersistentProvider.inMemory
    private var context: NSManagedObjectContext { persistentProvider.viewContext }
    
    private var useCase: DeleteDuplicatedEntriesUseCase = .live
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        for feed in try context.fetch(FeedModel.all) {
            context.delete(feed)
        }
        for entry in try context.fetch(EntryModel.all) {
            context.delete(entry)
        }
        try context.saveWithRollback()
    }
    
    func test_noDuplication() throws {
        _ = FeedModel(
            context,
            urlString: "https://feed1.com",
            entries: [
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/2",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 2)
                ),
            ]
        )
        _ = FeedModel(
            context,
            urlString: "https://feed2.com",
            entries: [
                .init(
                    context,
                    urlString: "https://feed2.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
                .init(
                    context,
                    urlString: "https://feed2.com/2",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 2)
                ),
                .init(
                    context,
                    urlString: "https://feed2.com/3",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 3)
                ),
            ]
        )
        try context.saveWithRollback()
        
        XCTAssertNoDifference(try context.fetch(FeedModel.all).count, 2)
        XCTAssertNoDifference(try context.fetch(EntryModel.all).count, 5)
        
        try useCase.execute(context)
        
        XCTAssertNoDifference(try context.fetch(FeedModel.all).count, 2)
        XCTAssertNoDifference(try context.fetch(EntryModel.all).count, 5)
    }
    
    func test_duplicatedFeeds() throws {
        _ = FeedModel(
            context,
            urlString: "https://feed1.com",
            entries: [
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/2",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 2)
                ),
            ]
        )
        let feed1 = FeedModel(
            context,
            urlString: "https://feed1.com",
            entries: [
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/2",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 2)
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/3",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 3)
                ),
            ]
        )
        try context.saveWithRollback()
        
        XCTAssertNoDifference(try context.fetch(FeedModel.all).count, 2)
        XCTAssertNoDifference(try context.fetch(EntryModel.all).count, 5)
        
        try useCase.execute(context)
        
        let remainingFeeds = try context.fetch(FeedModel.all)
        XCTAssertNoDifference(remainingFeeds.count, 1)
        let remainingFeed = try XCTUnwrap(remainingFeeds.first)
        XCTAssertNoDifference(remainingFeed.id, feed1.id)
        XCTAssertNoDifference(remainingFeed.entries?.count, 3)
        
        XCTAssertNoDifference(try context.fetch(EntryModel.all).count, 3)
    }
    
    func test_duplicatedEntries() throws {
        _ = FeedModel(
            context,
            urlString: "https://feed1.com",
            entries: [
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1),
                    read: false
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1),
                    read: true
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1),
                    read: false
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/2",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 2),
                    read: false
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/2",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 2),
                    read: false
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/3",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 3),
                    read: true
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/3",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 3),
                    read: true
                ),
            ]
        )
        try context.saveWithRollback()
        
        XCTAssertNoDifference(try context.fetch(FeedModel.all).count, 1)
        XCTAssertNoDifference(try context.fetch(EntryModel.all).count, 7)
        
        try useCase.execute(context)
        
        let remainingEntries = try context.fetch(EntryModel.all).sorted(by: { $0.url!.absoluteString < $1.url!.absoluteString })
        XCTAssertNoDifference(remainingEntries.count, 3)
        let entry1 = remainingEntries[0]
        XCTAssertNoDifference(entry1.url?.absoluteString, "https://feed1.com/1")
        XCTAssertNoDifference(entry1.read, true)
        let entry2 = remainingEntries[1]
        XCTAssertNoDifference(entry2.url?.absoluteString, "https://feed1.com/2")
        XCTAssertNoDifference(entry2.read, false)
        let entry3 = remainingEntries[2]
        XCTAssertNoDifference(entry3.url?.absoluteString, "https://feed1.com/3")
        XCTAssertNoDifference(entry3.read, true)
    }
}

private extension FeedModel {
    convenience init(
        _ context: NSManagedObjectContext,
        urlString: String,
        title: String = "Dummy Feed",
        entries: [EntryModel] = []
    ) {
        self.init(context: context)
        
        self.url = URL(string: urlString)
        self.title = title
        
        for entry in entries {
            addToEntries(entry)
        }
    }
}

private extension EntryModel {
    convenience init(
        _ context: NSManagedObjectContext,
        urlString: String,
        publishedAt: Date,
        read: Bool = false,
        title: String = "Dummy Entry"
    ) {
        self.init(context: context)
        
        self.url = URL(string: urlString)
        self.publishedAt = publishedAt
        self.title = title
        self.read = read
    }
}
