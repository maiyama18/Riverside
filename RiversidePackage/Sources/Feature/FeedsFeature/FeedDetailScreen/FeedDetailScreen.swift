import Models
import SwiftData
import SwiftUI

struct FeedDetailScreen: View {
    private let feed: FeedModel
    
    @Query private var entries: [EntryModel]
    
    init(feed: FeedModel) {
        self.feed = feed
        
        self._entries = Query(EntryModel.all(for: feed))
    }
    
    var body: some View {
        List {
            ForEach(entries) { entry in
                EntryRowView(entry: entry)
            }
        }
        .listStyle(.plain)
        .navigationTitle(feed.title)
    }
}
