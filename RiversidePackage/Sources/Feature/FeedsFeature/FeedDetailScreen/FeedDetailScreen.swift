import Models
import NavigationState
import SwiftData
import SwiftUI
import Utilities

@MainActor
struct FeedDetailScreen: View {
    private let feed: FeedModel
    
    @Query private var entries: [EntryModel]
    
    @AppStorage("unread-only-feed-detail") private var unreadOnly: Bool = true
    
    init(feed: FeedModel) {
        self.feed = feed
        self._entries = Query(EntryModel.all(for: feed))
    }
    
    var body: some View {
        Group {
            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label(
                            title: { Text("You've read all entries") },
                            icon: { Image(systemName: "list.dash") }
                        )
                    }
                )
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        EntryRowView(entry: entry)
                            .onTapGesture {
                                guard let url = URL(string: entry.url) else { return }
                                entry.read = true
                                showSafari(url: url)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(feed.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle(isOn: $unreadOnly) { Text("Unread only") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private var filteredEntries: [EntryModel] {
        entries.filter { unreadOnly ? $0.read == false : true }
    }
}
