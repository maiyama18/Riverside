import Models
import SwiftData
import SwiftUI

public struct RootScreen: View {
    @State private var selectedFeedID: PersistentIdentifier? = nil
    @State private var selectedEntryID: PersistentIdentifier? = nil
    
    @Query private var feeds: [FeedModel]
    @Query private var entries: [EntryModel]
    
    public init() {}
    
    private var filteredEntries: [EntryModel] {
        guard let selectedFeedID else { return entries }
        return entries.filter { $0.feed?.id == selectedFeedID }
    }
    
    private var selectedEntry: EntryModel? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.id == selectedEntryID })
    }    
    
    private var selectedFeed: FeedModel? {
        guard let selectedFeedID else { return nil }
        return feeds.first(where: { $0.id == selectedFeedID })
    }
    
    private var navigationTitle: String {
        if let selectedFeed {
            selectedFeed.title
        } else {
            "All"
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedFeedID) {
                Section {
                    Text("All")
                        .onTapGesture {
                            selectedFeedID = nil
                        }
                }
                
                Section {
                    ForEach(feeds) { feed in
                        HStack {
                            Text(feed.title)
                        }
                        .onTapGesture {
                            selectedFeedID = feed.id
                        }
                    }
                }
            }
        } content: {
            List(selection: $selectedEntryID) {
                ForEach(filteredEntries) { entry in
                    Text(entry.title)
                        .onTapGesture {
                            selectedEntryID = entry.id
                        }
                }
            }
            .navigationTitle(navigationTitle)
        } detail: {
            if let selectedEntry {
                EntryWebView(entry: selectedEntry)
            }
        }
    }
}

#Preview {
    RootScreen()
}
