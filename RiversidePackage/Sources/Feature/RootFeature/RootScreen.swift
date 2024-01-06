import Models
import SwiftData
import SwiftUI

public struct RootScreen: View {
    @State private var selectedFeedID: PersistentIdentifier? = nil
    @State private var selectedEntryID: PersistentIdentifier? = nil
    
    @Query(EntryModel.all) private var entries: [EntryModel]
    
    public init() {}
    
    private var filteredEntries: [EntryModel] {
        guard let selectedFeedID else { return entries }
        return entries.filter { $0.feed?.id == selectedFeedID }
    }
    
    private var selectedEntry: EntryModel? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.id == selectedEntryID })
    }    
    
    public var body: some View {
        NavigationSplitView {
            SidebarListView(selectedFeedID: $selectedFeedID)
        } content: {
            EntryListView(
                entries: filteredEntries,
                selectedEntryID: $selectedEntryID
            )
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
