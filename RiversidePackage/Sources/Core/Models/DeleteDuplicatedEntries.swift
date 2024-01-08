import SwiftData
import SwiftUI

public extension View {
    func deleteDuplicatedEntriesOnce() -> some View {
        modifier(DeleteDuplicatedEntriesOnceModifier())
    }
}

struct DeleteDuplicatedEntriesOnceModifier: ViewModifier {
    @Environment(\.modelContext) private var context
    
    @State private var deleteExecuted: Bool = false
    
    @Query(EntryModel.all, animation: .default) var entries: [EntryModel]
    @Query(FeedModel.all) var feeds: [FeedModel]
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !deleteExecuted else { return }
                deleteExecuted = true
                
                let duplicatedFeedsList = feeds
                    .grouped(by: \.url)
                    .values
                    .filter { $0.count > 1 }
                    .map { $0.sorted(by: { ($0.entries?.count ?? 0) > ($1.entries?.count ?? 0) }) }
                for duplicatedFeeds in duplicatedFeedsList {
                    for duplicatedFeed in duplicatedFeeds.dropFirst() {
                        context.delete(duplicatedFeed)
                        print("\(duplicatedFeed.title) deleted")
                    }
                }
                
                let duplicatedEntriesList = entries
                    .grouped(by: \.url)
                    .values
                    .filter { $0.count > 1 }
                    .map { $0.sorted(by: { ($0.read ? 1 : 0) > ($1.read ? 1 : 0) }) }
                for duplicatedEntries in duplicatedEntriesList {
                    for duplicatedEntry in duplicatedEntries.dropFirst() {
                        context.delete(duplicatedEntry)
                        print("\(duplicatedEntry.title) deleted")
                    }
                }
            }
    }
}
