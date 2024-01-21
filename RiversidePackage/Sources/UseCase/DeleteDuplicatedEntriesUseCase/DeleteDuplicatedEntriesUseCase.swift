import CoreData
import Dependencies
import Entities

public struct DeleteDuplicatedEntriesUseCase: Sendable {
    public var execute: @Sendable (_ context: NSManagedObjectContext) throws -> Void
}

extension DeleteDuplicatedEntriesUseCase {
    static var live: DeleteDuplicatedEntriesUseCase {
        .init(
            execute: { context in
                let allFeeds = try context.fetch(FeedModel.all)
                let duplicatedFeedsList = allFeeds
                    .grouped(by: \.url)
                    .values
                    .filter { $0.count > 1 }
                    .map { $0.sorted(by: { ($0.entries?.count ?? 0) > ($1.entries?.count ?? 0) }) }
                for duplicatedFeeds in duplicatedFeedsList {
                    for duplicatedFeed in duplicatedFeeds.dropFirst() {
                        context.delete(duplicatedFeed)
                    }
                }
                
                let allEntries = try context.fetch(EntryModel.all)
                let duplicatedEntriesList = allEntries
                    .grouped(by: \.url)
                    .values
                    .filter { $0.count > 1 }
                    .map { $0.sorted(by: { ($0.read ? 1 : 0) > ($1.read ? 1 : 0) }) }
                for duplicatedEntries in duplicatedEntriesList {
                    for duplicatedEntry in duplicatedEntries.dropFirst() {
                        context.delete(duplicatedEntry)
                    }
                }
                
                try context.saveWithRollback()
            }
        )
    }
}

extension DeleteDuplicatedEntriesUseCase: DependencyKey {
    public static let liveValue: DeleteDuplicatedEntriesUseCase = .live
}

public extension DependencyValues {
    var deleteDuplicatedEntriesUseCase: DeleteDuplicatedEntriesUseCase {
        get { self[DeleteDuplicatedEntriesUseCase.self] }
        set { self[DeleteDuplicatedEntriesUseCase.self] = newValue }
    }
}

