@testable import DeleteDuplicatedEntriesUseCase

import CustomDump
import CoreData
import Entities
import XCTest

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
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
                .init(
                    context,
                    urlString: "https://feed1.com/1",
                    publishedAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
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
        try context.saveWithRollback()
        
        XCTAssertNoDifference(try context.fetch(FeedModel.all).count, 1)
        XCTAssertNoDifference(try context.fetch(EntryModel.all).count, 4)
        
        try useCase.execute(context)
        
        let remainingEntries = try context.fetch(EntryModel.all)
        XCTAssertNoDifference(remainingEntries.count, 2)
        XCTAssertNoDifference(
            Set(remainingEntries.compactMap(\.url).map(\.absoluteString)),
            Set(["https://feed1.com/1", "https://feed1.com/2"])
        )
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
        title: String = "Dummy Entry"
    ) {
        self.init(context: context)
        
        self.url = URL(string: urlString)
        self.publishedAt = publishedAt
        self.title = title
    }
}
