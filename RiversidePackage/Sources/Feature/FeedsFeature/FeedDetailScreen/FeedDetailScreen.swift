import Models
import NavigationState
import SwiftData
import SwiftUI
import Utilities

@MainActor
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
                    .onTapGesture {
                        guard let url = URL(string: entry.url) else { return }
                        showSafari(url: url)
                    }
            }
        }
        .listStyle(.plain)
        .navigationTitle(feed.title)
    }
}
